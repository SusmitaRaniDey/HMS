/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-return */
import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { CreateZoomMeetingDto } from './dto/create-zoom-meeting.dto';

interface ZoomTokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
}

export interface ZoomMeetingResponse {
  id: string;
  join_url: string;
  start_url: string;
  password: string;
  status: string;
  start_time: string;
  duration: number;
  topic: string;
}

@Injectable()
export class ZoomService {
  constructor(
    private configService: ConfigService,

    @InjectRepository(Appointment)
    private appointmentRepo: Repository<Appointment>,
  ) {}

  // ─── OAuth Access Token ───────────────────────────────────────────────────

  private getZoomCredentials(): {
    accountId: string;
    clientId: string;
    clientSecret: string;
    hostUserId: string;
  } | null {
    const accountId = this.configService.get<string>('ZOOM_ACCOUNT_ID');
    const clientId = this.configService.get<string>('ZOOM_CLIENT_ID');
    const clientSecret = this.configService.get<string>('ZOOM_CLIENT_SECRET');
    const hostUserId = this.configService.get<string>('ZOOM_HOST_USER_ID');

    if (!accountId || !clientId || !clientSecret || !hostUserId) {
      return null;
    }

    return { accountId, clientId, clientSecret, hostUserId };
  }

  private async getAccessToken(): Promise<string> {
    const zoomCredentials = this.getZoomCredentials();

    if (!zoomCredentials) {
      throw new BadRequestException(
        'Zoom credentials are missing. Set ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, and ZOOM_CLIENT_SECRET in the API environment.',
      );
    }

    const { accountId, clientId, clientSecret } = zoomCredentials;
    const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString(
      'base64',
    );

    const response = await fetch(
      `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${accountId}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      },
    );

    if (!response.ok) {
      throw new UnauthorizedException('Failed to obtain Zoom access token');
    }

    const data = (await response.json()) as ZoomTokenResponse;
    return data.access_token;
  }

  private async createConfiguredFallbackMeeting(
    appointment: Appointment,
    dto: CreateZoomMeetingDto,
  ): Promise<Appointment> {
    const joinUrl = this.configService.get<string>('ZOOM_FALLBACK_JOIN_URL');
    const startUrl =
      this.configService.get<string>('ZOOM_FALLBACK_START_URL') || joinUrl;
    const password = this.configService.get<string>('ZOOM_FALLBACK_PASSWORD');
    const meetingId =
      this.configService.get<string>('ZOOM_FALLBACK_MEETING_ID') ||
      `fallback-${appointment.id}`;

    if (!joinUrl) {
      throw new BadRequestException(
        'Zoom is not configured. Set ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, and ZOOM_CLIENT_SECRET, or set ZOOM_FALLBACK_JOIN_URL to use a pre-created Zoom room.',
      );
    }

    await this.appointmentRepo.update(dto.appointmentId, {
      zoomMeetingId: meetingId,
      zoomJoinUrl: joinUrl,
      zoomStartUrl: startUrl,
      zoomPassword: password,
      meetingStatus: 'scheduled',
      startTime: dto.startTime,
      type: 'online',
    } as any);

    return this.appointmentRepo.findOne({
      where: { id: dto.appointmentId },
    }) as Promise<Appointment>;
  }

  // ─── Create Meeting ───────────────────────────────────────────────────────

  async createMeeting(dto: CreateZoomMeetingDto): Promise<Appointment> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: dto.appointmentId },
    });
    if (!appointment) throw new NotFoundException('Appointment not found');
    if (appointment.zoomMeetingId && appointment.zoomJoinUrl) {
      return appointment;
    }

    if (!this.getZoomCredentials() && dto.requireRealMeeting) {
      throw new BadRequestException(
        'Zoom meeting creation is unavailable. Configure ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, ZOOM_CLIENT_SECRET, and ZOOM_HOST_USER_ID before accepting emergency consultations.',
      );
    }

    if (!this.getZoomCredentials()) {
      return this.createConfiguredFallbackMeeting(appointment, dto);
    }

    const accessToken = await this.getAccessToken();

    const meetingPayload = {
      topic: dto.topic ?? 'Doctor-Patient Consultation',
      type: 2, // Scheduled meeting
      start_time: dto.startTime,
      duration: dto.duration ?? 30,
      timezone: 'Asia/Dhaka',
      settings: {
        join_before_host: true,
        waiting_room: false,
        auto_recording: 'none',
        mute_upon_entry: false,
      },
    };

    const { hostUserId } = this.getZoomCredentials()!;
    const response = await fetch(
      `https://api.zoom.us/v2/users/${encodeURIComponent(hostUserId)}/meetings`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(meetingPayload),
      },
    );

    if (!response.ok) {
      const errBody = await response.text();
      throw new InternalServerErrorException(
        `Zoom API error: ${response.status} - ${errBody}`,
      );
    }

    const meeting = (await response.json()) as ZoomMeetingResponse;

    // Persist Zoom data on the appointment
    await this.appointmentRepo.update(dto.appointmentId, {
      zoomMeetingId: String(meeting.id),
      zoomJoinUrl: meeting.join_url,
      zoomStartUrl: meeting.start_url,
      zoomPassword: meeting.password,
      meetingStatus: 'scheduled',
      startTime: dto.startTime,
      type: 'online',
    } as any);

    return this.appointmentRepo.findOne({
      where: { id: dto.appointmentId },
    }) as Promise<Appointment>;
  }

  // ─── Get Meeting Details ──────────────────────────────────────────────────

  async getMeeting(meetingId: string): Promise<ZoomMeetingResponse> {
    const accessToken = await this.getAccessToken();

    const response = await fetch(
      `https://api.zoom.us/v2/meetings/${meetingId}`,
      {
        headers: { Authorization: `Bearer ${accessToken}` },
      },
    );

    if (!response.ok) {
      throw new NotFoundException(`Zoom meeting ${meetingId} not found`);
    }

    return response.json() as Promise<ZoomMeetingResponse>;
  }

  // ─── Webhook Handler ──────────────────────────────────────────────────────

  async handleWebhook(
    body: Record<string, any>,
    providedToken: string,
  ): Promise<{ status: string }> {
    // Verify webhook token. If the secret isn't configured at all, fail
    // closed rather than silently accepting unauthenticated webhook calls —
    // an unset secret is a deployment mistake, not a reason to skip auth.
    const expectedToken = this.configService.get<string>(
      'ZOOM_WEBHOOK_SECRET_TOKEN',
    );
    if (!expectedToken) {
      throw new UnauthorizedException('Zoom webhook token is not configured');
    }
    if (providedToken !== expectedToken) {
      throw new UnauthorizedException('Invalid Zoom webhook token');
    }

    const event = body.event as string;
    const meetingId = body.payload?.object?.id as string | undefined;

    if (!meetingId) return { status: 'ignored' };

    if (event === 'meeting.started') {
      await this.appointmentRepo.update({ zoomMeetingId: String(meetingId) }, {
        meetingStatus: 'started',
      } as any);
    } else if (event === 'meeting.ended') {
      await this.appointmentRepo.update({ zoomMeetingId: String(meetingId) }, {
        meetingStatus: 'ended',
      } as any);
    }

    return { status: 'ok' };
  }
}
