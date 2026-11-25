/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminAuthGuard } from 'src/admin_auth/admin_authGuard';
import { AnyAuthGuard } from 'src/common/guards/any-auth.guard';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdatePaymentStatusDto } from './dto/update-payment-status.dto';
import { UpdateAppointmentDto } from './dto/update-appointment.dto';

/**
 * This controller is the internal/admin-facing appointment API. Patients and
 * doctors interact with appointments exclusively through the scoped,
 * ownership-checked routes in `patient.controller.ts` / `doctor.controller.ts`.
 * The four read-only slot-lookup routes below are the only ones legitimately
 * called by the patient app (to show availability before booking) and the
 * admin app, so they accept any authenticated user type; everything else
 * here is admin-only.
 */
@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Post()
  @UseGuards(AdminAuthGuard)
  create(@Body() dto: CreateAppointmentDto) {
    return this.appointmentsService.create(dto);
  }

  @Get()
  @UseGuards(AdminAuthGuard)
  findAll(@Query() query?: any) {
    if (
      query?.page ||
      query?.limit ||
      query?.status ||
      query?.doctorId ||
      query?.patientId ||
      query?.date
    ) {
      // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
      return this.appointmentsService.findAllPaginated(query as any);
    }
    return this.appointmentsService.findAll();
  }

  @Get('doctor/:doctorId/working-days')
  @UseGuards(AnyAuthGuard)
  getDoctorWorkingDays(@Param('doctorId', ParseIntPipe) doctorId: number) {
    return this.appointmentsService.getDoctorWorkingDays(doctorId);
  }

  @Get('doctor/:doctorId/available-slots')
  @UseGuards(AnyAuthGuard)
  getAvailableSlots(
    @Param('doctorId', ParseIntPipe) doctorId: number,
    @Query('date') date: string,
    @Query('type') type?: string,
  ) {
    return this.appointmentsService.getAvailableSlots(doctorId, date, type);
  }

  @Get('doctor/:doctorId/booked-times')
  @UseGuards(AnyAuthGuard)
  getBookedTimes(
    @Param('doctorId', ParseIntPipe) doctorId: number,
    @Query('date') date: string,
    @Query('type') type?: string,
  ) {
    return this.appointmentsService.getBookedTimes(doctorId, date, type);
  }

  @Get('doctor/:doctorId/time-slots')
  @UseGuards(AnyAuthGuard)
  getTimeSlots(
    @Param('doctorId', ParseIntPipe) doctorId: number,
    @Query('date') date: string,
    @Query('type') type?: string,
  ) {
    return this.appointmentsService.getTimeSlots(doctorId, date, type);
  }

  @Get('doctor/:doctorId')
  @UseGuards(AdminAuthGuard)
  findByDoctor(@Param('doctorId', ParseIntPipe) doctorId: number) {
    return this.appointmentsService.findByDoctor(doctorId);
  }

  @Get('patient/:patientId')
  @UseGuards(AdminAuthGuard)
  findByPatient(@Param('patientId', ParseIntPipe) patientId: number) {
    return this.appointmentsService.findByPatient(patientId);
  }

  @Get(':id')
  @UseGuards(AdminAuthGuard)
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.appointmentsService.findOne(id);
  }

  @Patch(':id/payment-status')
  @UseGuards(AdminAuthGuard)
  updatePaymentStatus(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: UpdatePaymentStatusDto,
  ) {
    return this.appointmentsService.updatePaymentStatus(id, body);
  }

  @Put(':id')
  @UseGuards(AdminAuthGuard)
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateAppointmentDto) {
    return this.appointmentsService.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminAuthGuard)
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.appointmentsService.remove(id);
  }
}
