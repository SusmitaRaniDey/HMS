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
  Res,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Response } from 'express';
import type { PatientContext } from './decorators/current-patient.decorator';
import { CurrentPatient as CP } from './decorators/current-patient.decorator';
import { BookAppointmentDto } from './dto/book-appointment.dto';
import { BookDiagnosticDto } from './dto/book-diagnostic.dto';
import { CancelAppointmentDto } from './dto/cancel-appointment.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { ConfirmPaymentDto } from './dto/confirm-payment.dto';
import { LoginPatientDto } from './dto/loginPatientDto';
import { RegisterEmailDto } from './dto/registerEmailDto';
import { RegisterPhoneDto } from './dto/registerPhoneDto';
import { UpdatePasswordDto } from './dto/update-password.dto';
import { UpdatePatientProfileDto } from './dto/update-patient-profile.dto';
import { PatientAuthGuard } from './guards/patient-auth.guard';
import { PatientService } from './patient.service';
import { EmergencyConsultationService } from 'src/emergency-consultation/emergency-consultation.service';
import {
  CompleteEmergencyPaymentDto,
  EmergencyPaymentCallbackDto,
  InitiateEmergencyPaymentDto,
} from 'src/emergency-consultation/dto/emergency-payment.dto';

@Controller('patient')
export class PatientController {
  constructor(
    private readonly patientService: PatientService,
    private readonly emergencyService: EmergencyConsultationService,
  ) {}

  // ============ AUTHENTICATION ENDPOINTS ============
  @Post('auth/register-email')
  registerWithEmail(@Body() dto: RegisterEmailDto) {
    return this.patientService.registerWithEmail(dto);
  }

  @Post('auth/register-phone')
  registerWithPhone(@Body() dto: RegisterPhoneDto) {
    return this.patientService.registerWithPhone(dto);
  }

  // 5 attempts per minute per IP, to slow down credential-stuffing/brute
  // force against patient accounts.
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('auth/login')
  loginPatient(@Body() dto: LoginPatientDto) {
    return this.patientService.loginPatient(dto);
  }

  // ============ PROFILE MANAGEMENT (Protected) ============
  @UseGuards(PatientAuthGuard)
  @Get('profile')
  getPatientProfile(@CP() patient: PatientContext) {
    return this.patientService.getPatientProfile(patient.id);
  }

  @UseGuards(PatientAuthGuard)
  @Patch('profile')
  updatePatientProfile(
    @CP() patient: PatientContext,
    @Body() dto: UpdatePatientProfileDto,
  ) {
    return this.patientService.updatePatientProfile(patient.id, dto);
  }

  @UseGuards(PatientAuthGuard)
  @Post('profile/change-password')
  updatePassword(
    @CP() patient: PatientContext,
    @Body() dto: UpdatePasswordDto,
  ) {
    return this.patientService.updatePassword(
      patient.id,
      dto.oldPassword,
      dto.newPassword,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('emergency-doctors')
  getEmergencyDoctors() {
    return this.emergencyService.listAvailable();
  }

  @UseGuards(PatientAuthGuard)
  @Post('emergency-consultations/payment/initiate')
  initiateEmergencyPayment(
    @CP() patient: PatientContext,
    @Body() dto: InitiateEmergencyPaymentDto,
  ) {
    return this.emergencyService.initiatePayment(patient.id, dto.doctorId);
  }

  @UseGuards(PatientAuthGuard)
  @Post('emergency-consultations/payment/success')
  completeEmergencyPayment(
    @CP() patient: PatientContext,
    @Body() dto: CompleteEmergencyPaymentDto,
  ) {
    return this.emergencyService.completePayment(patient.id, dto);
  }

  @UseGuards(PatientAuthGuard)
  @Post('emergency-consultations/payment/fail')
  failEmergencyPayment(
    @CP() patient: PatientContext,
    @Body() dto: CompleteEmergencyPaymentDto,
  ) {
    return this.emergencyService.failPayment(patient.id, dto.transactionId);
  }

  @UseGuards(PatientAuthGuard)
  @Post('emergency-consultations/payment/cancel')
  cancelEmergencyPayment(
    @CP() patient: PatientContext,
    @Body() dto: CompleteEmergencyPaymentDto,
  ) {
    return this.emergencyService.cancelPayment(patient.id, dto.transactionId);
  }

  @Post('emergency-consultations/payment/callback/success')
  paymentSuccessCallback(@Body() dto: EmergencyPaymentCallbackDto) {
    return this.emergencyService.handleGatewayCallback('success', dto);
  }

  @Post('emergency-consultations/payment/callback/fail')
  paymentFailCallback(@Body() dto: EmergencyPaymentCallbackDto) {
    return this.emergencyService.handleGatewayCallback('failed', dto);
  }

  @Post('emergency-consultations/payment/callback/cancel')
  paymentCancelCallback(@Body() dto: EmergencyPaymentCallbackDto) {
    return this.emergencyService.handleGatewayCallback('cancelled', dto);
  }

  @UseGuards(PatientAuthGuard)
  @Get('emergency-consultations/:appointmentId')
  getEmergencyConsultation(
    @CP() patient: PatientContext,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
  ) {
    return this.emergencyService.getBooking(patient.id, appointmentId);
  }

  // ============ APPOINTMENT MANAGEMENT (Protected) ============
  @UseGuards(PatientAuthGuard)
  @Post('appointments')
  bookAppointment(
    @CP() patient: PatientContext,
    @Body() dto: BookAppointmentDto,
  ) {
    return this.patientService.bookAppointment(patient.id, dto);
  }

  // Confirms an online payment for an appointment created above. The
  // booking itself always starts unpaid; this is the only way it can
  // become "paid", and it re-verifies the transaction with SSLCommerz
  // server-side rather than trusting the client's report.
  @UseGuards(PatientAuthGuard)
  @Post('appointments/:id/confirm-payment')
  confirmAppointmentPayment(
    @CP() patient: PatientContext,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ConfirmPaymentDto,
  ) {
    return this.patientService.confirmAppointmentPayment(id, patient.id, dto);
  }
  @UseGuards(PatientAuthGuard)
  @Get('appointments/check-existing')
  checkExistingAppointment(
    @CP() patient: PatientContext,
    @Query('doctorId') doctorId: number,
    @Query('date') date: string,
  ) {
    return this.patientService.checkExistingAppointment(
      patient.id,
      doctorId,
      date,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('appointments')
  getPatientAppointments(
    @CP() patient: PatientContext,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.patientService.getPatientAppointments(
      patient.id,
      page || 1,
      limit || 10,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('appointments/upcoming')
  getUpcomingAppointments(@CP() patient: PatientContext) {
    return this.patientService.getUpcomingAppointments(patient.id);
  }

  @UseGuards(PatientAuthGuard)
  @Get('appointments/history')
  getAppointmentHistory(
    @CP() patient: PatientContext,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.patientService.getAppointmentHistory(
      patient.id,
      page || 1,
      limit || 10,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Delete('appointments/:appointmentId')
  cancelAppointment(
    @CP() patient: PatientContext,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
    @Body() dto: CancelAppointmentDto,
  ) {
    return this.patientService.cancelAppointment(
      patient.id,
      appointmentId,
      dto.reason,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('appointments/:appointmentId/join-meeting')
  getAppointmentMeetingJoinUrl(
    @CP() patient: PatientContext,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
  ) {
    return this.patientService.getAppointmentMeetingJoinUrl(
      patient.id,
      appointmentId,
    );
  }

  // ============ DIAGNOSTIC MANAGEMENT (Protected) ============
  // One card per item_code — see PatientService.getAllDiagnostics for the
  // grouping rationale (a test panel like CBC has many parameter rows).
  @UseGuards(PatientAuthGuard)
  @Get('diagnostics')
  getAllDiagnostics(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('search') search?: string,
    @Query('category') category?: string,
  ) {
    return this.patientService.getAllDiagnostics(
      page || 1,
      limit || 20,
      search,
      category,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('diagnostics/categories')
  getDiagnosticCategories() {
    return this.patientService.getDiagnosticCategories();
  }

  // Full detail for one test panel: summary + every parameter row
  // (Parameter/Normal Range/Unit/Notes) sharing that item_code.
  @UseGuards(PatientAuthGuard)
  @Get('diagnostics/item/:itemCode')
  getDiagnosticByItemCode(@Param('itemCode') itemCode: string) {
    return this.patientService.getDiagnosticByItemCode(itemCode);
  }

  @UseGuards(PatientAuthGuard)
  @Post('bookings')
  bookDiagnostic(
    @CP() patient: PatientContext,
    @Body() dto: BookDiagnosticDto,
  ) {
    return this.patientService.bookDiagnostic(patient.id, dto);
  }

  // Confirms an online payment for a diagnostic booking — same pattern as
  // appointments/:id/confirm-payment above.
  @UseGuards(PatientAuthGuard)
  @Post('bookings/:id/confirm-payment')
  confirmDiagnosticPayment(
    @CP() patient: PatientContext,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ConfirmPaymentDto,
  ) {
    return this.patientService.confirmDiagnosticBookingPayment(
      id,
      patient.id,
      dto,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('bookings')
  getPatientBookings(
    @CP() patient: PatientContext,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.patientService.getPatientBookings(
      patient.id,
      page || 1,
      limit || 10,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('bookings/upcoming')
  getUpcomingBookings(@CP() patient: PatientContext) {
    return this.patientService.getUpcomingBookings(patient.id);
  }

  @UseGuards(PatientAuthGuard)
  @Get('bookings/history')
  getBookingHistory(
    @CP() patient: PatientContext,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.patientService.getBookingHistory(
      patient.id,
      page || 1,
      limit || 10,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Delete('bookings/:bookingId')
  cancelBooking(
    @CP() patient: PatientContext,
    @Param('bookingId', ParseIntPipe) bookingId: number,
    @Body() dto: CancelBookingDto,
  ) {
    return this.patientService.cancelBooking(patient.id, bookingId, dto.reason);
  }

  // ============ INVOICE DOWNLOAD (Public — opened via url_launcher) ============
  @Get('appointments/:appointmentId/invoice')
  async downloadAppointmentInvoice(
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const buffer =
      await this.patientService.generateAppointmentInvoice(appointmentId);
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="invoice_appointment_${appointmentId}.pdf"`,
    });
    return new StreamableFile(buffer);
  }

  @Get('bookings/:bookingId/invoice')
  async downloadBookingInvoice(
    @Param('bookingId', ParseIntPipe) bookingId: number,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const buffer = await this.patientService.generateBookingInvoice(bookingId);
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="invoice_booking_${bookingId}.pdf"`,
    });
    return new StreamableFile(buffer);
  }

  // ============ DOCTOR BROWSING (Protected) ============
  @UseGuards(PatientAuthGuard)
  @Get('doctors')
  getAllDoctors(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('search') search?: string,
    @Query('specialty') specialty?: string,
  ) {
    return this.patientService.getAllDoctors(
      page || 1,
      limit || 20,
      search,
      specialty,
    );
  }

  @UseGuards(PatientAuthGuard)
  @Get('doctors/:doctorId')
  getDoctorById(@Param('doctorId', ParseIntPipe) doctorId: number) {
    return this.patientService.getDoctorById(doctorId);
  }
}
