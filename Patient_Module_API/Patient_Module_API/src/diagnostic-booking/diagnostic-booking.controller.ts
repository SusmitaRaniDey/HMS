import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminAuthGuard } from 'src/admin_auth/admin_authGuard';
import { CurrentAdmin, type AdminContext } from 'src/admin_auth/decorators/current_admin_decorator';
import { DiagnosticBookingService } from './diagnostic-booking.service';
import { CreateDiagnosticBookingDto } from './dto/create-diagnostic-booking.dto';
import { UpdateDiagnosticBookingDto } from './dto/update-diagnostic-booking.dto';

/**
 * Admins manage diagnostic bookings through their own guarded
 * `/admin-auth/diagnostic-bookings/*` routes; this bare controller is not
 * used by any known client for creating/reading bookings (patients use
 * `/patient/bookings`), so it's locked down to admin-only end to end.
 */
@Controller('diagnostic-booking')
@UseGuards(AdminAuthGuard)
export class DiagnosticBookingController {
  constructor(private readonly bookingService: DiagnosticBookingService) {}

  @Post()
  create(@Body() dto: CreateDiagnosticBookingDto) {
    return this.bookingService.create(dto);
  }

  @Get()
  findAllBooking(@Query() query?: any) {
    if (query?.page || query?.limit || query?.status || query?.patientId) {
      return this.bookingService.findAllPaginated(query as any);
    }
    return this.bookingService.findAll();
  }

  @Get('user/:patientId')
  findBookingByUser(@Param('patientId', ParseIntPipe) patientId: number) {
    return this.bookingService.findBookingsByUser(patientId);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.bookingService.findOne(id);
  }

  @Patch(':id')
  updateBooking(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateDiagnosticBookingDto,
  ) {
    return this.bookingService.update(id, dto);
  }

  @Patch(':id/approve')
  approveBooking(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
    @Body() body: { patientFcmToken?: string },
  ) {
    return this.bookingService.approveBooking(
      id,
      admin.id,
      body.patientFcmToken,
    );
  }

  @Patch(':id/reject')
  rejectBooking(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
    @Body() body: { reason?: string; patientFcmToken?: string },
  ) {
    return this.bookingService.rejectBooking(
      id,
      admin.id,
      body.reason,
      body.patientFcmToken,
    );
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.bookingService.remove(id);
  }
}
