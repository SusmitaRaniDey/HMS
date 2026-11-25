import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Response } from 'express';
import { UpdateAppointmentDto } from 'src/appointments/dto/update-appointment.dto';
import { UpdateDiagnosticBookingDto } from 'src/diagnostic-booking/dto/update-diagnostic-booking.dto';
import { CreateDiagnosticDto } from 'src/diagnostics/dto/create-diagnostic.dto';
import { UpdateDiagnosticDto } from 'src/diagnostics/dto/update-diagnostic.dto';
import { CreateDoctorDto } from 'src/doctor/dto/create-doctor.dto';
import { UpdateDoctorDto } from 'src/doctor/dto/update-doctor.dto';
import { DiagnosticBookingService } from 'src/diagnostic-booking/diagnostic-booking.service';
import { AdminAuthService } from './admin_auth.service';
import { AdminAuthGuard } from './admin_authGuard';
import type { AdminContext } from './decorators/current_admin_decorator';
import { CurrentAdmin } from './decorators/current_admin_decorator';
import { HasPermission } from './decorators/has-permission.decorator';
import { HasRole } from './decorators/has-role.decorator';
import { BulkStatusDto } from './dto/bulk-status.dto';
import {
  CancelAppointmentDto,
  ReassignAppointmentDto,
  RescheduleAppointmentDto,
} from './dto/cancel-appointment.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { CreateAdminDto } from './dto/create_admin.dto';
import { LoginAdminDto } from './dto/login_admin.dto';
import { UpdateAdminDto } from './dto/update_admin.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AdminPermission } from './enums/admin-permission.enum';
import { AdminRole } from './enums/admin-role.enum';
import { PatientService } from 'src/patient/patient.service';
import {
  AdminBookAppointmentDto,
  AdminBookDiagnosticDto,
} from './dto/admin-booking.dto';
import { EmergencyConsultationService } from 'src/emergency-consultation/emergency-consultation.service';
import { AdminSetEmergencyAvailabilityDto } from 'src/emergency-consultation/dto/emergency-availability.dto';

@Controller('admin-auth')
export class AdminAuthController {
  constructor(
    private readonly adminAuthService: AdminAuthService,
    private readonly patientService: PatientService,
    private readonly emergencyService: EmergencyConsultationService,
    private readonly diagnosticBookingService: DiagnosticBookingService,
  ) {}

  // Only an existing super-admin can create new admin accounts — this was
  // previously unguarded, which let anyone register their own admin
  // account and then (via the missing self-promotion check that's now
  // fixed in AdminAuthService.updateAdmin) escalate straight to
  // super-admin.
  @UseGuards(AdminAuthGuard)
  @HasRole(AdminRole.SUPER_ADMIN)
  @Post('create')
  createAdmin(@Body() dto: CreateAdminDto) {
    return this.adminAuthService.createAdmin(dto);
  }

  // 5 attempts per minute per IP, to slow down credential-stuffing/brute
  // force against admin accounts — the highest-privilege login in the
  // system.
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('login')
  loginAdmin(@Body() dto: LoginAdminDto) {
    return this.adminAuthService.loginAdmin(dto);
  }

  @UseGuards(AdminAuthGuard)
  @Get('emergency-consultations/dashboard')
  getEmergencyDashboard() {
    return this.emergencyService.dashboard();
  }

  @UseGuards(AdminAuthGuard)
  @Get('emergency-doctors')
  getEmergencyAvailability() {
    return this.emergencyService.listAllAvailability();
  }

  @UseGuards(AdminAuthGuard)
  @Post('emergency-doctors')
  setEmergencyAvailability(@Body() dto: AdminSetEmergencyAvailabilityDto) {
    return this.emergencyService.setAvailability(dto.doctorId, dto, true);
  }

  @UseGuards(AdminAuthGuard)
  @Post('emergency-doctors/:doctorId/off')
  turnEmergencyAvailabilityOff(
    @Param('doctorId', ParseIntPipe) doctorId: number,
  ) {
    return this.emergencyService.turnOff(doctorId, true);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_ADMIN)
  @Get('all-admin')
  getAllAdmins() {
    return this.adminAuthService.getAllAdmins();
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_ADMIN)
  @Get('admins/:id')
  getAdminById(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getAdmin(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_ADMIN)
  @Patch('admins/:id')
  patchAdmin(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateAdminDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.updateAdmin(id, dto, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_ADMIN)
  @Put('admins/:id')
  updateAdmin(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateAdminDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.updateAdmin(id, dto, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_ADMIN)
  @Delete('admins/:id')
  deleteAdmin(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.deleteAdmin(id, admin.id, admin.email);
  }

  // ========== DIAGNOSTICS ==========
  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DIAGNOSTIC)
  @Get('diagnostics')
  getAllDiagnostics() {
    return this.adminAuthService.getAllDiagnostics();
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.CREATE_DIAGNOSTIC)
  @Post('diagnostics')
  createDiagnostic(
    @Body() dto: CreateDiagnosticDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.createDiagnostic(dto, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DIAGNOSTIC)
  @Get('diagnostics/grouped')
  getGroupedDiagnostics(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('search') search?: string,
  ) {
    return this.adminAuthService.getGroupedDiagnostics(page, limit, search);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DIAGNOSTIC)
  @Get('diagnostics/item/:itemCode')
  getDiagnosticsByItemCode(@Param('itemCode') itemCode: string) {
    return this.adminAuthService.getDiagnosticsByItemCode(itemCode);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DIAGNOSTIC)
  @Get('diagnostics/:id')
  getDiagnosticById(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getDiagnostic(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_DIAGNOSTIC)
  @Patch('diagnostics/:id')
  updateDiagnostic(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateDiagnosticDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.updateDiagnostic(
      id,
      dto,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.DELETE_DIAGNOSTIC)
  @Delete('diagnostics/:id')
  deleteDiagnostic(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.deleteDiagnostic(id, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_DIAGNOSTIC_STATUS)
  @Patch('diagnostics/:id/status')
  toggleDiagnosticStatus(
    @Param('id', ParseIntPipe) id: number,
    @Body('active') active: boolean,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.toggleDiagnosticStatus(
      id,
      active,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.IMPORT_DIAGNOSTIC)
  @Post('diagnostics/import')
  importDiagnostics(
    @Body() dto: CreateDiagnosticDto[],
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.createDiagnosticsBulk(
      dto,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.EXPORT_DIAGNOSTIC)
  @Get('diagnostics/export')
  exportDiagnostics(@Res({ passthrough: true }) res: Response) {
    res.type('text/csv');
    return this.adminAuthService.exportDiagnosticsCsv();
  }

  // ========== DOCTORS ==========
  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DOCTOR)
  @Get('doctors')
  getAllDoctors() {
    return this.adminAuthService.getAllDoctors();
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.CREATE_DOCTOR)
  @Post('doctors')
  createDoctor(
    @Body() dto: CreateDoctorDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.createDoctor(dto, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DOCTOR)
  @Get('doctors/:id')
  getDoctorById(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getDoctor(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DOCTOR)
  @Get('doctors/:id/appointments')
  getAppointmentsByDoctor(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getAppointmentsByDoctor(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_DOCTOR)
  @Patch('doctors/:id')
  updateDoctor(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateDoctorDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.updateDoctor(id, dto, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.DELETE_DOCTOR)
  @Delete('doctors/:id')
  deleteDoctor(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.deleteDoctor(id, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_DOCTOR)
  @Get('doctors-with-appointments')
  getAllDoctorsWithAppointments() {
    return this.adminAuthService.getAllDoctorsWithAppointments();
  }

  // ========== DIAGNOSTIC BOOKINGS ==========
  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_BOOKING)
  @Get('diagnostic-bookings')
  getAllDiagnosticBookings(
    @Query('page') page: number,
    @Query('limit') limit: number,
    @Query('status') status: string,
    @Query('patientId') patientId: number,
    @Query('scheduleDate') scheduleDate: string,
  ) {
    return this.adminAuthService.getBookingsPaginated({
      page: page || 1,
      limit: limit || 10,
      status,
      patientId,
      scheduleDate,
    });
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.BULK_UPDATE_BOOKING)
  @Patch('diagnostic-bookings/bulk-status')
  bulkUpdateBookingStatus(
    @Body() dto: BulkStatusDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.bulkUpdateBookingStatus(
      dto.ids,
      dto.status,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.CANCEL_BOOKING)
  @Post('diagnostic-bookings/:id/cancel')
  cancelBooking(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: CancelBookingDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.cancelBookingWorkflow(
      id,
      dto.cancellationReason,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_BOOKING)
  @Get('diagnostic-bookings/:id')
  getBookingById(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getBooking(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_BOOKING)
  @Patch('diagnostic-bookings/:id')
  updateBooking(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateDiagnosticBookingDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.updateBooking(id, dto, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.DELETE_BOOKING)
  @Delete('diagnostic-bookings/:id')
  deleteBooking(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.deleteBooking(id, admin.id, admin.email);
  }

  // Dedicated approve/reject actions (as opposed to the generic PATCH
  // above) so a pending-only status-transition guard and the patient
  // notification are always applied consistently.
  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_BOOKING)
  @Patch('diagnostic-bookings/:id/approve')
  approveDiagnosticBooking(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
    @Body() body: { patientFcmToken?: string },
  ) {
    return this.diagnosticBookingService.approveBooking(
      id,
      admin.id,
      body?.patientFcmToken,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_BOOKING)
  @Patch('diagnostic-bookings/:id/reject')
  rejectDiagnosticBooking(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
    @Body() body: { reason?: string; patientFcmToken?: string },
  ) {
    return this.diagnosticBookingService.rejectBooking(
      id,
      admin.id,
      body?.reason,
      body?.patientFcmToken,
    );
  }

  // ========== APPOINTMENTS ==========
  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_APPOINTMENT)
  @Post('appointments')
  async createAppointmentForPatient(@Body() body: AdminBookAppointmentDto) {
    const { patientId, newPatient, ...dto } = body;
    if (!patientId && !newPatient) {
      throw new BadRequestException('Select a patient or enter a new patient');
    }
    if (patientId && newPatient) {
      throw new BadRequestException('Choose either a registered or new patient');
    }
    const patient = newPatient
      ? await this.patientService.createAdminPatient(newPatient)
      : null;
    // An admin collects the consultation fee at the hospital counter. These
    // bookings are final immediately and must never enter the pending queue.
    return this.patientService.bookAppointment(patientId ?? patient!.id, {
      ...dto,
      status: 'confirmed',
      isPaid: 'paid',
      paymentMethod: 'pay_in_hospital',
      paymentStatus: 'completed',
      transactionId: undefined,
      bankTransactionId: undefined,
    });
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_BOOKING)
  @Post('diagnostic-bookings')
  async createDiagnosticBookingForPatient(@Body() body: AdminBookDiagnosticDto) {
    const { patientId, newPatient, ...dto } = body;
    if (!patientId && !newPatient) {
      throw new BadRequestException('Select a patient or enter a new patient');
    }
    if (patientId && newPatient) {
      throw new BadRequestException('Choose either a registered or new patient');
    }
    const patient = newPatient
      ? await this.patientService.createAdminPatient(newPatient)
      : null;
    return this.patientService.bookDiagnostic(
      patientId ?? patient!.id,
      dto,
      true,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_APPOINTMENT)
  @Get('appointments/:id/invoice')
  async appointmentInvoice(@Param('id', ParseIntPipe) id: number, @Res() response: Response) {
    const pdf = await this.patientService.generateAppointmentInvoice(id);
    response.set({ 'Content-Type': 'application/pdf', 'Content-Disposition': `inline; filename="invoice_appointment_${id}.pdf"` });
    response.end(pdf);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_BOOKING)
  @Get('diagnostic-bookings/:id/invoice')
  async diagnosticBookingInvoice(@Param('id', ParseIntPipe) id: number, @Res() response: Response) {
    const pdf = await this.patientService.generateBookingInvoice(id);
    response.set({ 'Content-Type': 'application/pdf', 'Content-Disposition': `inline; filename="invoice_booking_${id}.pdf"` });
    response.end(pdf);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_APPOINTMENT)
  @Get('appointments')
  getAllAppointments(
    @Query('page') page: number,
    @Query('limit') limit: number,
    @Query('status') status: string,
    @Query('doctorId') doctorId: number,
    @Query('patientId') patientId: number,
    @Query('date') date: string,
  ) {
    return this.adminAuthService.getAppointmentsPaginated({
      page: page || 1,
      limit: limit || 10,
      status,
      doctorId,
      patientId,
      date,
    });
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.BULK_UPDATE_APPOINTMENT)
  @Post('appointments/bulk-status')
  bulkUpdateAppointmentStatus(
    @Body() dto: BulkStatusDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.bulkUpdateAppointmentStatus(
      dto.ids,
      dto.status,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.CANCEL_APPOINTMENT)
  @Post('appointments/:id/cancel')
  cancelAppointment(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: CancelAppointmentDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.cancelAppointmentWorkflow(
      id,
      dto.cancellationReason,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_APPOINTMENT)
  @Patch('appointments/:id/reschedule')
  rescheduleAppointment(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: RescheduleAppointmentDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.rescheduleAppointment(
      id,
      dto,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.REASSIGN_APPOINTMENT)
  @Patch('appointments/:id/reassign')
  reassignAppointment(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ReassignAppointmentDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.reassignAppointmentToDoctor(
      id,
      dto.newDoctorId,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_APPOINTMENT)
  @Get('appointments/:id')
  getAppointmentById(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getAppointment(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_APPOINTMENT)
  @Patch('appointments/:id')
  updateAppointment(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateAppointmentDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.updateAppointment(
      id,
      dto,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.DELETE_APPOINTMENT)
  @Delete('appointments/:id')
  deleteAppointment(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.deleteAppointment(id, admin.id, admin.email);
  }

  // ========== USERS ==========
  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_USER)
  @Get('users')
  getAllUsers() {
    return this.adminAuthService.getAllUsers();
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_USER)
  @Get('users/:id/prescriptions')
  getPatientHistory(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getPatientHistory(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.READ_USER)
  @Get('users/:id')
  getUserById(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getUser(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.UPDATE_USER)
  @Patch('users/:id')
  updateUser(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateUserDto,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.updateUser(id, dto, admin.id, admin.email);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.DELETE_USER)
  @Delete('users/:id')
  deleteUser(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.deleteUser(id, admin.id, admin.email);
  }

  // ========== ROLE MANAGEMENT (SuperAdmin only) ==========
  @UseGuards(AdminAuthGuard)
  @HasRole(AdminRole.SUPER_ADMIN)
  @Post('admins/:id/assign-role')
  assignRoleToAdmin(
    @Param('id', ParseIntPipe) id: number,
    @Body('role') role: AdminRole,
    @CurrentAdmin() admin: AdminContext,
  ) {
    return this.adminAuthService.assignRoleToAdmin(
      id,
      role,
      admin.id,
      admin.email,
    );
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_ROLES)
  @Get('admins/:id/role')
  getAdminRole(@Param('id', ParseIntPipe) id: number) {
    return this.adminAuthService.getAdminRole(id);
  }

  @UseGuards(AdminAuthGuard)
  @HasPermission(AdminPermission.MANAGE_ADMIN)
  @Get('admins-with-roles')
  listAllAdminsWithRoles() {
    return this.adminAuthService.listAllAdminsWithRoles();
  }

  @UseGuards(AdminAuthGuard)
  @Get('roles')
  getAllRoles() {
    return this.adminAuthService.getAllRoles();
  }

  @UseGuards(AdminAuthGuard)
  @Get('roles/:role/permissions')
  getRolePermissions(@Param('role') role: AdminRole) {
    return this.adminAuthService.getRolePermissions(role);
  }
}
