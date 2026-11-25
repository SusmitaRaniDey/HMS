import { IsBoolean, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateZoomMeetingDto {
  @IsNumber()
  appointmentId!: number;

  @IsString()
  startTime!: string; // ISO 8601 datetime

  @IsString()
  @IsOptional()
  topic?: string;

  @IsNumber()
  @IsOptional()
  duration?: number; // minutes, default 30

  /**
   * Instant consultations must never masquerade a shared fallback room as a
   * newly-created meeting. Scheduled legacy flows may still opt into the
   * configured fallback by leaving this false.
   */
  @IsBoolean()
  @IsOptional()
  requireRealMeeting?: boolean;
}
