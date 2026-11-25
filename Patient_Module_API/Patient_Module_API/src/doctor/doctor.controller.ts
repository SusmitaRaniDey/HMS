/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Patch,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { DoctorService } from './doctor.service';
import { ChangePasswordDto, DoctorLoginDto } from './dto/doctor-auth.dto';
import { DoctorAuthGuard } from './guards/doctor-auth.guard';
import { GetDoctor } from './get-doctor.decorator';
import { EmergencyConsultationService } from 'src/emergency-consultation/emergency-consultation.service';
import { SetEmergencyAvailabilityDto } from 'src/emergency-consultation/dto/emergency-availability.dto';

@Controller('doctor')
export class DoctorController {
  constructor(
    private readonly doctorService: DoctorService,
    private readonly emergencyService: EmergencyConsultationService,
  ) {}

  // ============= Authentication =============
  // 5 attempts per minute per IP, to slow down credential-stuffing/brute
  // force against doctor accounts.
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('auth/login')
  loginDoctor(@Body() loginDto: DoctorLoginDto) {
    return this.doctorService.loginDoctor(loginDto);
  }

  // ============= Profile =============
  @Get('profile')
  @UseGuards(DoctorAuthGuard)
  getDoctorProfile(@GetDoctor() doctor: { id: number }) {
    return this.doctorService.getDoctorProfile(doctor.id);
  }

  @Post('profile/change-password')
  @UseGuards(DoctorAuthGuard)
  changePassword(
    @GetDoctor() doctor: { id: number },
    @Body() changePasswordDto: ChangePasswordDto,
  ) {
    return this.doctorService.changePassword(doctor.id, changePasswordDto);
  }

  @Get('emergency-availability')
  @UseGuards(DoctorAuthGuard)
  getEmergencyAvailability(@GetDoctor() doctor: { id: number }) {
    return this.emergencyService.getDoctorAvailability(doctor.id);
  }

  @Patch('emergency-availability')
  @UseGuards(DoctorAuthGuard)
  setEmergencyAvailability(
    @GetDoctor() doctor: { id: number },
    @Body() dto: SetEmergencyAvailabilityDto,
  ) {
    return this.emergencyService.setAvailability(doctor.id, dto);
  }

  @Post('emergency-availability/off')
  @UseGuards(DoctorAuthGuard)
  turnEmergencyAvailabilityOff(@GetDoctor() doctor: { id: number }) {
    return this.emergencyService.turnOff(doctor.id);
  }

  // ============= Appointments =============
  @Get('appointments')
  @UseGuards(DoctorAuthGuard)
  getAllAppointments(
    @GetDoctor() doctor: { id: number },
    @Query('page', new ParseIntPipe({ optional: true })) page: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number,
    @Query('status') status: string,
  ) {
    return this.doctorService.getDoctorAppointments(
      doctor.id,
      page || 1,
      limit || 20,
      status,
    );
  }

  @Get('appointments/pending')
  @UseGuards(DoctorAuthGuard)
  getPendingAppointments(@GetDoctor() doctor: { id: number }) {
    return this.doctorService.getPendingAppointments(doctor.id);
  }

  @Get('appointments/confirmed')
  @UseGuards(DoctorAuthGuard)
  getConfirmedAppointments(@GetDoctor() doctor: { id: number }) {
    return this.doctorService.getConfirmedAppointments(doctor.id);
  }

   @Get('appointments/cancelled')
  @UseGuards(DoctorAuthGuard)
  getCancelledAppointments(@GetDoctor() doctor: { id: number }) {
    return this.doctorService.getCancelledAppointments(doctor.id);
  }

  @Get('appointments/today')
  @UseGuards(DoctorAuthGuard)
  getTodayAppointments(@GetDoctor() doctor: { id: number }) {
    return this.doctorService.getTodayAppointments(doctor.id);
  }

  @Get('appointments/upcoming')
  @UseGuards(DoctorAuthGuard)
  getUpcomingAppointments(@GetDoctor() doctor: { id: number }) {
    return this.doctorService.getUpcomingAppointments(doctor.id);
  }

  @Get('appointments/history')
  @UseGuards(DoctorAuthGuard)
  getAppointmentHistory(
    @GetDoctor() doctor: { id: number },
    @Query('page', new ParseIntPipe({ optional: true })) page: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit: number,
  ) {
    return this.doctorService.getDoctorAppointmentHistory(
      doctor.id,
      page || 1,
      limit || 20,
    );
  }

  @Get('appointments/:appointmentId')
  @UseGuards(DoctorAuthGuard)
  getAppointmentDetails(
    @GetDoctor() doctor: { id: number },
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
  ) {
    return this.doctorService.getAppointmentDetails(doctor.id, appointmentId);
  }

  @Get('appointments/:appointmentId/start-meeting')
  @UseGuards(DoctorAuthGuard)
  getAppointmentMeetingStartUrl(
    @GetDoctor() doctor: { id: number },
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
  ) {
    return this.doctorService.getAppointmentMeetingStartUrl(
      doctor.id,
      appointmentId,
    );
  }
}
