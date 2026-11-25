import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AdminAuthGuard } from 'src/admin_auth/admin_authGuard';
import { ZoomService } from './zoom.service';
import { CreateZoomMeetingDto } from './dto/create-zoom-meeting.dto';

/**
 * Patients and doctors never call these routes directly — join/start links
 * are issued through the scoped, ownership-checked appointment endpoints
 * in patient.controller.ts / doctor.controller.ts, which call ZoomService
 * in-process. These raw HTTP routes are only for admin/ops use, so they're
 * locked down to admin; the webhook route is Zoom's own server calling in
 * and is authenticated separately via ZOOM_WEBHOOK_SECRET_TOKEN.
 */
@Controller('zoom')
export class ZoomController {
  constructor(private readonly zoomService: ZoomService) {}

  @Post('create-meeting')
  @UseGuards(AdminAuthGuard)
  createMeeting(@Body() dto: CreateZoomMeetingDto) {
    return this.zoomService.createMeeting(dto);
  }

  @Get('meeting/:id')
  @UseGuards(AdminAuthGuard)
  getMeeting(@Param('id') id: string) {
    return this.zoomService.getMeeting(id);
  }

  @Post('webhook')
  handleWebhook(
    @Body() body: Record<string, any>,
    @Headers('Authorization') authHeader: string,
  ) {
    // Zoom sends token as plain string in a custom header or in body.token
    const providedToken =
      (body.token as string) ?? authHeader ?? '';
    return this.zoomService.handleWebhook(body, providedToken);
  }
}
