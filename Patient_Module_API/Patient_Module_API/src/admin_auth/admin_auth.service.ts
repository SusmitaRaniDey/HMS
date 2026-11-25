/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import bcrypt from 'bcrypt';
import { UpdateAppointmentDto } from 'src/appointments/dto/update-appointment.dto';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { UpdateDiagnosticBookingDto } from 'src/diagnostic-booking/dto/update-diagnostic-booking.dto';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { CreateDiagnosticDto } from 'src/diagnostics/dto/create-diagnostic.dto';
import { UpdateDiagnosticDto } from 'src/diagnostics/dto/update-diagnostic.dto';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { CreateDoctorDto } from 'src/doctor/dto/create-doctor.dto';
import { UpdateDoctorDto } from 'src/doctor/dto/update-doctor.dto';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Prescription } from 'src/prescriptions/entities/prescription.entity';
import { ZoomService } from 'src/zoom/zoom.service';
import { In, Repository } from 'typeorm';
import { CreateAdminDto } from './dto/create_admin.dto';
import { LoginAdminDto } from './dto/login_admin.dto';
import { UpdateAdminDto } from './dto/update_admin.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { Admin } from './entities/admin.entity';
import { AdminRole } from './enums/admin-role.enum';
import { ROLE_PERMISSIONS } from './enums/role-permissions.map';
import { AdminAuditLogService } from './services/admin-audit-log.service';
import { RescheduleAppointmentDto } from './dto/cancel-appointment.dto';

@Injectable()
export class AdminAuthService {
  constructor(
    @InjectRepository(Admin) private adminRepo: Repository<Admin>,

    @InjectRepository(Diagnostic)
    private diagnosticRepo: Repository<Diagnostic>,

    @InjectRepository(Doctor)
    private doctorRepo: Repository<Doctor>,

    @InjectRepository(DiagnosticBooking)
    private bookingRepo: Repository<DiagnosticBooking>,

    @InjectRepository(Appointment)
    private appointmentRepo: Repository<Appointment>,

    @InjectRepository(Patients)
    private userRepo: Repository<Patients>,

    @InjectRepository(Prescription)
    private prescriptionRepo: Repository<Prescription>,

    private jwtService: JwtService,
    private configService: ConfigService,
    private auditLogService: AdminAuditLogService,
    private zoomService: ZoomService,
  ) {}

  private getAppointmentDayName(dateStr: string): string {
    const date = new Date(dateStr);
    return [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ][date.getUTCDay()];
  }

  private buildOnlineMeetingStartTime(appointment: Appointment): string {
    if (appointment.startTime) return appointment.startTime;

    const dayName = this.getAppointmentDayName(appointment.date);
    const onlineSlot = appointment.doctor?.onlineSchedule?.find(
      (slot) => slot.day?.toLowerCase() === dayName.toLowerCase(),
    );
    const time = onlineSlot?.startTime || '09:00';
    const normalizedTime = time.split(':').length === 2 ? `${time}:00` : time;

    return `${appointment.date}T${normalizedTime}.000Z`;
  }

  private cloneSchedule<
    T extends { day: string; startTime: string; endTime: string },
  >(schedule: T[]): T[] {
    return schedule.map((slot) => ({
      day: slot.day,
      startTime: slot.startTime,
      endTime: slot.endTime,
    })) as T[];
  }

  private normalizeCreateDoctorSchedulePayload(dto: CreateDoctorDto) {
    const payload = { ...dto };

    if (payload.onlineSchedule === null) {
      delete payload.onlineSchedule;
    }

    if (
      payload.onlineSchedule === undefined &&
      payload.workingDays &&
      payload.workingDays.length > 0
    ) {
      payload.onlineSchedule = this.cloneSchedule(payload.workingDays);
    }

    return payload;
  }

  private normalizeUpdateDoctorSchedulePayload(dto: UpdateDoctorDto) {
    const payload = { ...dto } as UpdateDoctorDto & {
      onlineSchedule?: CreateDoctorDto['onlineSchedule'] | null;
      workingDays?: CreateDoctorDto['workingDays'] | null;
    };

    if (payload.onlineSchedule === null) {
      delete payload.onlineSchedule;
    }

    if (payload.workingDays === null) {
      delete payload.workingDays;
    }

    return payload;
  }

  private async ensureZoomMeetingForConfirmedOnlineAppointment(
    appointmentId: number,
  ): Promise<Appointment> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
      relations: ['doctor', 'patient'],
    });

    if (!appointment) throw new NotFoundException('Appointment not found');
    if (appointment.type !== 'online') return appointment;
    if (appointment.zoomMeetingId && appointment.zoomJoinUrl)
      return appointment;

    return this.zoomService.createMeeting({
      appointmentId: appointment.id,
      startTime: this.buildOnlineMeetingStartTime(appointment),
      topic: `Online consultation: ${appointment.doctor?.name ?? 'Doctor'} and ${
        appointment.patient?.name ?? 'Patient'
      }`,
      duration: 30,
    });
  }

  async createAdmin(dto: CreateAdminDto) {
    const existing = await this.adminRepo.findOneBy({ email: dto.email });
    if (existing) {
      throw new BadRequestException('Admin with this email already exists');
    }

    const hash = await bcrypt.hash(dto.password, 10);

    const newAdmin = this.adminRepo.create({
      ...dto,
      password: hash,
      role: AdminRole.ADMIN, // Default role
    });

    const saved = await this.adminRepo.save(newAdmin);

    // Log admin creation
    await this.auditLogService.logAction(
      saved.id,
      saved.email,
      'CREATE_ADMIN',
      'Admin',
      saved.id,
      { email: saved.email, name: saved.name },
    );

    return {
      id: saved.id,
      name: saved.name,
      email: saved.email,
      phone: saved.phone,
      role: saved.role,
    };
  }

  async loginAdmin(dto: LoginAdminDto) {
    const admin = await this.adminRepo
      .createQueryBuilder('admin')
      .addSelect('admin.password')
      .where('admin.email = :email', { email: dto.email })
      .getOne();

    if (!admin) {
      throw new NotFoundException('Admin not found');
    }
    const isPasswordMatch = await bcrypt.compare(dto.password, admin.password);
    if (!isPasswordMatch) {
      throw new UnauthorizedException('Wrong password');
    }

    const payload = {
      id: admin.id,
      email: admin.email,
      role: admin.role,
    };
    const token = this.jwtService.sign(payload);

    const safeAdmin = {
      id: admin.id,
      name: admin.name,
      email: admin.email,
      phone: admin.phone,
      role: admin.role,
    };

    // Log successful login
    await this.auditLogService.logAction(
      admin.id,
      admin.email,
      'LOGIN',
      'Admin',
      admin.id,
    );

    return {
      success: true,
      message: 'Login successful',
      token,
      admin: safeAdmin,
    };
  }

  async getAllAdmins() {
    const admins = await this.adminRepo.find();
    return admins.map((a) => ({
      id: a.id,
      name: a.name,
      email: a.email,
      phone: a.phone,
      role: a.role,
      createdAt: a.createdAt,
    }));
  }

  async getAdmin(id: number) {
    const admin = await this.adminRepo.findOne({ where: { id } });
    if (!admin) throw new NotFoundException('Admin not found');
    return {
      id: admin.id,
      name: admin.name,
      email: admin.email,
      phone: admin.phone,
      role: admin.role,
      createdAt: admin.createdAt,
      updatedAt: admin.updatedAt,
    };
  }

  async updateAdmin(
    id: number,
    dto: UpdateAdminDto,
    adminId: number,
    adminEmail: string,
    callerRole?: AdminRole,
  ) {
    const admin = await this.adminRepo.findOne({ where: { id } });
    if (!admin) throw new NotFoundException('Admin not found');

    // Only a super-admin may grant SUPER_ADMIN or ADMIN roles, and nobody
    // may change their own role — both close the self-promotion path where
    // a regular admin (who already holds MANAGE_ADMIN) could otherwise
    // escalate themselves or a colleague to super-admin.
    if (dto.role && dto.role !== admin.role) {
      if (id === adminId) {
        throw new BadRequestException('You cannot change your own role');
      }
      if (
        callerRole !== AdminRole.SUPER_ADMIN &&
        (dto.role === AdminRole.SUPER_ADMIN || dto.role === AdminRole.ADMIN)
      ) {
        throw new BadRequestException(
          'Only a super-admin can grant admin or super-admin privileges',
        );
      }
      if (admin.role === AdminRole.SUPER_ADMIN && dto.role !== AdminRole.SUPER_ADMIN) {
        const superAdminCount = await this.adminRepo.count({
          where: { role: AdminRole.SUPER_ADMIN },
        });
        if (superAdminCount <= 1) {
          throw new BadRequestException(
            'Cannot remove the last remaining super-admin',
          );
        }
      }
    }

    // Check email uniqueness if email is being changed
    if (dto.email && dto.email !== admin.email) {
      const existing = await this.adminRepo.findOneBy({ email: dto.email });
      if (existing) {
        throw new BadRequestException('Admin with this email already exists');
      }
    }

    // Hash password if provided
    if (dto.password) {
      (dto as any).password = await bcrypt.hash(dto.password, 10);
    }

    await this.adminRepo.update(id, dto);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'UPDATE_ADMIN',
      'Admin',
      id,
      { ...dto, password: dto.password ? '[REDACTED]' : undefined },
    );

    return this.getAdmin(id);
  }

  async deleteAdmin(id: number, adminId: number, adminEmail: string) {
    const admin = await this.adminRepo.findOne({ where: { id } });
    if (!admin) throw new NotFoundException('Admin not found');

    // Prevent self-deletion
    if (admin.id === adminId) {
      throw new BadRequestException('You cannot delete your own account');
    }

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'DELETE_ADMIN',
      'Admin',
      id,
      { deletedAdminEmail: admin.email, deletedAdminName: admin.name },
    );

    return this.adminRepo.delete(id);
  }

  async getAllDiagnostics() {
    return await this.diagnosticRepo.find();
  }

  // One summary row per item_code (a test panel can have many parameter
  // rows, e.g. CBC has separate rows for Hemoglobin, RBC, WBC, ...).
  // Pagination is applied to the grouped tests, not the raw parameter rows,
  // so `total` reflects the number of unique item codes (e.g. 117), not the
  // number of underlying diagnostic_data rows (e.g. 231).
  async getGroupedDiagnostics(page = 1, limit = 10, search?: string) {
    const diags = await this.diagnosticRepo.find({ order: { id: 'ASC' } });
    const groups = new Map<string, Diagnostic[]>();

    for (const d of diags) {
      const key = d.item_code ?? `__id_${d.id}`;
      const existing = groups.get(key);
      if (existing) {
        existing.push(d);
      } else {
        groups.set(key, [d]);
      }
    }

    let allGroups = Array.from(groups.values()).map((rows) => {
      const first = rows[0];
      return {
        id: first.id,
        item_code: first.item_code,
        category: first.category,
        test_name: first.test_name,
        price: first.price,
        is_active: first.is_active,
        image: first.image,
        parameterCount: rows.length,
      };
    });

    const totalParameters = allGroups.reduce(
      (sum, g) => sum + g.parameterCount,
      0,
    );

    const q = search?.trim().toLowerCase();
    if (q) {
      allGroups = allGroups.filter(
        (g) =>
          g.test_name?.toLowerCase().includes(q) ||
          g.category?.toLowerCase().includes(q) ||
          g.item_code?.toLowerCase().includes(q),
      );
    }

    const safePage = page > 0 ? page : 1;
    const safeLimit = [10, 25, 50, 100].includes(limit) ? limit : 10;
    const total = allGroups.length;
    const start = (safePage - 1) * safeLimit;
    const data = allGroups.slice(start, start + safeLimit);

    return { data, total, page: safePage, limit: safeLimit, totalParameters };
  }

  async getDiagnosticsByItemCode(itemCode: string) {
    const rows = await this.diagnosticRepo.find({
      where: { item_code: itemCode },
      order: { id: 'ASC' },
    });
    if (!rows.length) {
      throw new NotFoundException(
        `No diagnostic found with item_code "${itemCode}"`,
      );
    }
    return rows;
  }

  async getAllDoctors() {
    return await this.doctorRepo.find();
  }

  async getAllDiagnosticBookings() {
    const bookings = await this.bookingRepo.find({
      order: { createdAt: 'DESC' },
    });
    return bookings.map((b) => ({
      id: b.id,
      diagnostic: b.diagnostic,
      patient: {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        id: (b.patient as any)?.id,
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        name: (b.patient as any)?.name,
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        phone: (b.patient as any)?.phone,
      },
      scheduleDate: b.scheduleDate,
      status: b.status,
      notes: b.notes,
      createdAt: b.createdAt,
    }));
  }

  async getAllAppointments() {
    const appointments = await this.appointmentRepo.find();
    return appointments.map((a) => ({
      id: a.id,
      doctor: a.doctor,
      patient: {
        id: a.patient.id,
        name: a.patient.name,
        phone: a.patient.phone,
      },
      date: a.date,
      serialNumber: a.serialNumber,
      status: a.status,
    }));
  }

  async getAllUsers() {
    const users = await this.userRepo.find();
    return users.map((u) => ({
      id: u.id,
      name: u.name,
      phone: u.phone,
      email: u.email,
    }));
  }

  // Diagnostics CRUD with Audit Logging
  async createDiagnostic(
    dto: CreateDiagnosticDto,
    adminId: number,
    adminEmail: string,
  ) {
    const d = this.diagnosticRepo.create(dto);
    const saved = await this.diagnosticRepo.save(d);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'CREATE_DIAGNOSTIC',
      'Diagnostic',
      saved.id,
      dto,
    );

    return saved;
  }

  async getDiagnostic(id: number) {
    const d = await this.diagnosticRepo.findOne({ where: { id } });
    if (!d) throw new NotFoundException('Diagnostic not found');
    return d;
  }

  async updateDiagnostic(
    id: number,
    dto: UpdateDiagnosticDto,
    adminId: number,
    adminEmail: string,
  ) {
    await this.diagnosticRepo.update(id, dto);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'UPDATE_DIAGNOSTIC',
      'Diagnostic',
      id,
      dto,
    );

    return this.getDiagnostic(id);
  }

  async deleteDiagnostic(id: number, adminId: number, adminEmail: string) {
    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'DELETE_DIAGNOSTIC',
      'Diagnostic',
      id,
    );

    return this.diagnosticRepo.delete(id);
  }

  async toggleDiagnosticStatus(
    id: number,
    active: boolean,
    adminId: number,
    adminEmail: string,
  ) {
    await this.diagnosticRepo.update(id, { is_active: active });

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'TOGGLE_DIAGNOSTIC_STATUS',
      'Diagnostic',
      id,
      { is_active: active },
    );

    return this.getDiagnostic(id);
  }

  async createDiagnosticsBulk(
    diagnostics: CreateDiagnosticDto[],
    adminId: number,
    adminEmail: string,
  ) {
    const items = this.diagnosticRepo.create(diagnostics);
    const saved = await this.diagnosticRepo.save(items);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'BULK_IMPORT_DIAGNOSTICS',
      'Diagnostic',
      undefined,
      { count: saved.length },
    );

    return saved;
  }

  async exportDiagnosticsCsv() {
    const diags = await this.diagnosticRepo.find();

    const header =
      'id,item_code,category,test_name,parameter,normal_range,unit,price,notes,is_active,image\n';

    const rows = diags
      .map((d) => {
        const notes = (d.notes ?? '').replace(/"/g, '""');
        const image = d.image ?? '';
        const fields = [
          d.id,
          `"${d.item_code ?? ''}"`,
          `"${d.category}"`,
          `"${d.test_name}"`,
          `"${d.parameter ?? ''}"`,
          `"${d.normal_range ?? ''}"`,
          `"${d.unit ?? ''}"`,
          d.price,
          `"${notes}"`,
          d.is_active,
          `"${image}"`,
        ];
        return fields.join(',');
      })
      .join('\n');

    return header + rows;
  }

  // Doctors CRUD with Audit Logging
  async createDoctor(
    dto: CreateDoctorDto,
    adminId: number,
    adminEmail: string,
  ) {
    // Check if email already exists
    const existingDoctor = await this.doctorRepo.findOneBy({
      email: dto.email,
    });
    if (existingDoctor) {
      throw new BadRequestException('Doctor with this email already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    const doctorPayload = this.normalizeCreateDoctorSchedulePayload(dto);

    // Create doctor with hashed password
    const d = this.doctorRepo.create({
      ...doctorPayload,
      password: hashedPassword,
    });
    const saved = await this.doctorRepo.save(d);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'CREATE_DOCTOR',
      'Doctor',
      saved.id,
      {
        name: dto.name,
        email: dto.email,
        specialty: dto.specialty,
      },
    );

    return {
      id: saved.id,
      name: saved.name,
      email: saved.email,
      phone: saved.phone,
      specialty: saved.specialty,
      degrees: saved.degrees,
      experience: saved.experience,
      working_at: saved.working_at,
      fee: saved.fee,
      onlineFee: saved.onlineFee,
      offlineFee: saved.offlineFee,
      message: 'Doctor registered successfully',
    };
  }

  async getDoctor(id: number) {
    const d = await this.doctorRepo.findOneBy({ id });
    if (!d) throw new NotFoundException('Doctor not found');
    return d;
  }

  async updateDoctor(
    id: number,
    dto: UpdateDoctorDto,
    adminId: number,
    adminEmail: string,
  ) {
    const updatePayload = this.normalizeUpdateDoctorSchedulePayload(dto);
    await this.doctorRepo.update(id, updatePayload);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'UPDATE_DOCTOR',
      'Doctor',
      id,
      updatePayload,
    );

    return this.getDoctor(id);
  }

  async deleteDoctor(id: number, adminId: number, adminEmail: string) {
    // Check if doctor exists
    const doctor = await this.doctorRepo.findOne({ where: { id } });
    if (!doctor) {
      throw new BadRequestException('Doctor not found');
    }

    // Delete all appointments for this doctor first (cascade delete)
    await this.appointmentRepo.delete({ doctorId: id });

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'DELETE_DOCTOR',
      'Doctor',
      id,
    );

    return this.doctorRepo.delete(id);
  }

  async getAppointmentsByDoctor(doctorId: number) {
    const appointments = await this.appointmentRepo.find({
      where: { doctorId },
      relations: ['patient', 'doctor'],
      order: { date: 'DESC' },
    });

    return appointments.map((a) => ({
      id: a.id,
      date: a.date,
      serialNumber: a.serialNumber,
      status: a.status,
      patient: {
        id: a.patient?.id,
        name: a.patient?.name,
        phone: a.patient?.phone,
      },
    }));
  }

  async getAllDoctorsWithAppointments() {
    const doctors = await this.doctorRepo.find();
    const results: any[] = [];

    for (const doctor of doctors) {
      const appointments = await this.getAppointmentsByDoctor(doctor.id);
      results.push({
        ...doctor,
        appointmentsCount: appointments.length,
        recentAppointments: appointments.slice(0, 5),
      });
    }

    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return results;
  }

  // Diagnostic bookings CRUD
  async getBooking(id: number) {
    const b = await this.bookingRepo.findOne({ where: { id } });
    if (!b) throw new NotFoundException('Booking not found');
    return {
      id: b.id,
      scheduleDate: b.scheduleDate,
      status: b.status,
      notes: b.notes,
      cancellationReason: b.cancellationReason,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
      diagnostic: b.diagnostic,
      patient: {
        id: (b.patient as any)?.id,
        name: (b.patient as any)?.name,
        phone: (b.patient as any)?.phone,
        email: (b.patient as any)?.email,
      },
    };
  }

  async updateBooking(
    id: number,
    dto: UpdateDiagnosticBookingDto,
    adminId: number,
    adminEmail: string,
  ) {
    await this.bookingRepo.update(id, dto);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'UPDATE_BOOKING',
      'DiagnosticBooking',
      id,
      dto,
    );

    return this.getBooking(id);
  }

  async deleteBooking(id: number, adminId: number, adminEmail: string) {
    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'DELETE_BOOKING',
      'DiagnosticBooking',
      id,
    );

    return this.bookingRepo.delete(id);
  }

  // Appointments CRUD
  async getAppointment(id: number) {
    const a = await this.appointmentRepo.findOne({ where: { id } });
    if (!a) throw new NotFoundException('Appointment not found');
    return a;
  }

  async updateAppointment(
    id: number,
    dto: UpdateAppointmentDto,
    adminId: number,
    adminEmail: string,
  ) {
    if ((dto as any).status === 'confirmed') {
      await this.ensureZoomMeetingForConfirmedOnlineAppointment(id);
    }

    await this.appointmentRepo.update(id, dto);
    const updatedAppointment = await this.getAppointment(id);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'UPDATE_APPOINTMENT',
      'Appointment',
      id,
      dto,
    );

    return updatedAppointment;
  }

  async rescheduleAppointment(
    id: number,
    dto: RescheduleAppointmentDto,
    adminId: number,
    adminEmail: string,
  ) {
    const updated = await this.appointmentRepo.manager.transaction(
      'SERIALIZABLE',
      async (manager) => {
        const appointmentRepo = manager.getRepository(Appointment);
        const doctorRepo = manager.getRepository(Doctor);
        const appointment = await appointmentRepo.findOne({
          where: { id },
          relations: ['doctor', 'patient'],
          lock: { mode: 'pessimistic_write' },
        });
        if (!appointment) throw new NotFoundException('Appointment not found');
        if (['cancelled', 'completed'].includes(appointment.status)) {
          throw new BadRequestException(
            `A ${appointment.status} appointment cannot be rescheduled`,
          );
        }

        const doctor = await doctorRepo.findOne({
          where: { id: dto.doctorId },
        });
        if (!doctor) throw new BadRequestException('Doctor not found');

        const date = new Date(`${dto.date}T00:00:00.000Z`);
        if (
          Number.isNaN(date.getTime()) ||
          dto.date < new Date().toISOString().slice(0, 10)
        ) {
          throw new BadRequestException(
            'Appointment date is expired or invalid',
          );
        }
        const dayName = this.getAppointmentDayName(dto.date);
        const schedules =
          appointment.type === 'online'
            ? doctor.onlineSchedule
            : doctor.workingDays;
        const schedule = schedules?.find(
          (item) => item.day.toLowerCase() === dayName.toLowerCase(),
        );
        if (!schedule) {
          throw new BadRequestException(
            `Doctor is not available for ${appointment.type} appointments on ${dayName}`,
          );
        }

        const toMinutes = (value: string) => {
          const [hours, minutes] = value.split(':').map(Number);
          return hours * 60 + minutes;
        };
        const requested = toMinutes(dto.timeSlot);
        const scheduleStart = toMinutes(schedule.startTime);
        const scheduleEnd = toMinutes(schedule.endTime);
        if (
          requested < scheduleStart ||
          requested + 5 > scheduleEnd ||
          (requested - scheduleStart) % 5 !== 0
        ) {
          throw new BadRequestException(
            "Selected slot is outside the doctor's working hours",
          );
        }
        const today = new Date().toISOString().slice(0, 10);
        if (dto.date === today) {
          const now = new Date();
          if (requested <= now.getHours() * 60 + now.getMinutes()) {
            throw new BadRequestException('Selected slot has already expired');
          }
        }

        const patientConflict = await appointmentRepo
          .createQueryBuilder('appointment')
          .setLock('pessimistic_write')
          .where('appointment.id != :id', { id })
          .andWhere('appointment.patientId = :patientId', {
            patientId: appointment.patientId,
          })
          .andWhere('appointment.doctorId = :doctorId', {
            doctorId: dto.doctorId,
          })
          .andWhere('appointment.date = :date', { date: dto.date })
          .andWhere('appointment.status IN (:...statuses)', {
            statuses: ['pending', 'confirmed', 'completed'],
          })
          .getOne();
        if (patientConflict) {
          throw new BadRequestException(
            'This patient already has an appointment with this doctor on the selected date.',
          );
        }

        const conflict = await appointmentRepo
          .createQueryBuilder('appointment')
          .setLock('pessimistic_write')
          .where('appointment.id != :id', { id })
          .andWhere('appointment.doctorId = :doctorId', {
            doctorId: dto.doctorId,
          })
          .andWhere('appointment.date = :date', { date: dto.date })
          .andWhere('appointment.timeSlot = :timeSlot', {
            timeSlot: dto.timeSlot,
          })
          .andWhere('appointment.type = :type', { type: appointment.type })
          .andWhere('appointment.status IN (:...statuses)', {
            statuses: ['pending', 'confirmed'],
          })
          .getOne();
        if (conflict)
          throw new BadRequestException('Selected slot is already booked');

        const oldDoctor = appointment.doctor;
        const oldDate = appointment.date;
        const oldSlot = appointment.timeSlot;
        appointment.doctorId = doctor.id;
        appointment.doctor = doctor;
        appointment.date = dto.date;
        appointment.timeSlot = dto.timeSlot;
        if (appointment.type === 'online') {
          // The schedules and timeSlot values are Bangladesh wall-clock times.
          // Preserve that meaning in the ISO value instead of marking the
          // selected time as UTC (which makes clients add six hours).
          appointment.startTime = `${dto.date}T${dto.timeSlot}:00.000+06:00`;
        }
        const saved = await appointmentRepo.save(appointment);

        await this.auditLogService.logAction(
          adminId,
          adminEmail,
          'RESCHEDULE_APPOINTMENT',
          'Appointment',
          id,
          {
            oldDoctor: { id: oldDoctor?.id, name: oldDoctor?.name },
            newDoctor: { id: doctor.id, name: doctor.name },
            oldDate,
            newDate: dto.date,
            oldSlot,
            newSlot: dto.timeSlot,
            reason: dto.reason || null,
          },
        );
        return saved;
      },
    );

    return this.getAppointment(updated.id);
  }

  async deleteAppointment(id: number, adminId: number, adminEmail: string) {
    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'DELETE_APPOINTMENT',
      'Appointment',
      id,
    );

    return this.appointmentRepo.delete(id);
  }

  // Users CRUD
  async getUser(id: number) {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return {
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
    };
  }

  async updateUser(
    id: number,
    dto: UpdateUserDto,
    adminId: number,
    adminEmail: string,
  ) {
    if (dto.password) {
      dto.password = await bcrypt.hash(dto.password, 10);
    }

    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    await this.userRepo.update(id, dto as any);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'UPDATE_USER',
      'User',
      id,
      { ...dto, password: dto.password ? '[REDACTED]' : undefined },
    );

    return this.getUser(id);
  }

  async deleteUser(id: number, adminId: number, adminEmail: string) {
    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'DELETE_USER',
      'User',
      id,
    );

    return this.userRepo.delete(id);
  }

  // Appointment Workflows
  async getAppointmentsPaginated(query?: {
    page?: number;
    limit?: number;
    status?: string;
    doctorId?: number;
    patientId?: number;
    date?: string;
  }) {
    const page = query?.page || 1;
    const limit = query?.limit || 10;
    const where: Record<string, any> = {};

    if (query?.status) where['status'] = query.status;
    if (query?.doctorId) where['doctorId'] = query.doctorId;
    if (query?.patientId) where['patientId'] = query.patientId;
    if (query?.date) where['date'] = query.date;

    const [data, total] = await this.appointmentRepo.findAndCount({
      where: where as any,
      relations: ['doctor', 'patient'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return {
      data: data.map((a) => ({
        id: a.id,
        date: a.date,
        serialNumber: a.serialNumber,
        status: a.status,
        type: a.type,
        isPaid: a.isPaid,
        paymentMethod: a.paymentMethod,
        paymentStatus: a.paymentStatus,
        transactionId: a.transactionId,
        bankTransactionId: a.bankTransactionId,
        paidAmount: a.paidAmount,
        zoomMeetingId: a.zoomMeetingId,
        zoomJoinUrl: a.zoomJoinUrl,
        zoomStartUrl: a.zoomStartUrl,
        zoomPassword: a.zoomPassword,
        meetingStatus: a.meetingStatus,
        startTime: a.startTime,
        timeSlot: a.timeSlot,
        prescriptionId: a.prescriptionId,
        cancellationReason: a.cancellationReason,
        createdAt: a.createdAt,
        updatedAt: a.updatedAt,
        patient: {
          id: a.patient?.id,
          name: a.patient?.name,
          phone: a.patient?.phone,
          email: a.patient?.email,
        },
        doctor: {
          id: a.doctor?.id,
          name: a.doctor?.name,
          specialty: a.doctor?.specialty,
          fee: a.doctor?.fee,
        },
      })),
      total,
      page,
      limit,
    };
  }

  async cancelAppointmentWorkflow(
    id: number,
    cancellationReason: string,
    adminId: number,
    adminEmail: string,
  ) {
    const appt = await this.appointmentRepo.findOne({
      where: { id },
      relations: ['doctor', 'patient'],
    });

    if (!appt) throw new NotFoundException('Appointment not found');
    if (['cancelled', 'completed'].includes(appt.status)) {
      throw new BadRequestException(
        `A ${appt.status} appointment cannot be cancelled`,
      );
    }

    appt.status = 'cancelled';
    appt.cancellationReason = cancellationReason;
    await this.appointmentRepo.save(appt);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'CANCEL_APPOINTMENT',
      'Appointment',
      id,
      { cancellationReason },
    );

    return {
      id: appt.id,
      date: appt.date,
      serialNumber: appt.serialNumber,
      status: appt.status,
      cancellationReason: appt.cancellationReason,
      patient: {
        id: appt.patient?.id,
        name: appt.patient?.name,
        phone: appt.patient?.phone,
      },
      doctor: {
        id: appt.doctor?.id,
        name: appt.doctor?.name,
        specialty: appt.doctor?.specialty,
      },
    };
  }

  async bulkUpdateAppointmentStatus(
    ids: number[],
    status: string,
    adminId: number,
    adminEmail: string,
  ) {
    if (status === 'confirmed') {
      for (const id of ids) {
        await this.ensureZoomMeetingForConfirmedOnlineAppointment(id);
      }
    }

    const result = await this.appointmentRepo.update({ id: In(ids) }, {
      status,
    } as any);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'BULK_UPDATE_APPOINTMENT_STATUS',
      'Appointment',
      undefined,
      { ids, status, count: result.affected },
    );

    return {
      updated: result.affected || 0,
      status,
    };
  }

  async reassignAppointmentToDoctor(
    id: number,
    newDoctorId: number,
    adminId: number,
    adminEmail: string,
  ) {
    const appointment = await this.appointmentRepo.findOne({
      where: { id },
      relations: ['doctor', 'patient'],
    });

    if (!appointment) throw new NotFoundException('Appointment not found');

    const doctor = await this.doctorRepo.findOneBy({ id: newDoctorId });
    if (!doctor) throw new NotFoundException('Doctor not found');

    const oldDoctorId = appointment.doctorId;
    appointment.doctorId = newDoctorId;
    appointment.doctor = doctor;
    await this.appointmentRepo.save(appointment);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'REASSIGN_APPOINTMENT',
      'Appointment',
      id,
      { oldDoctorId, newDoctorId },
    );

    return {
      id: appointment.id,
      date: appointment.date,
      serialNumber: appointment.serialNumber,
      status: appointment.status,
      patient: {
        id: appointment.patient?.id,
        name: appointment.patient?.name,
        phone: appointment.patient?.phone,
      },
      doctor: {
        id: appointment.doctor?.id,
        name: appointment.doctor?.name,
        specialty: appointment.doctor?.specialty,
      },
    };
  }

  // Diagnostic Booking Workflows
  async getBookingsPaginated(query?: {
    page?: number;
    limit?: number;
    status?: string;
    patientId?: number;
    scheduleDate?: string;
  }) {
    const page = query?.page || 1;
    const limit = query?.limit || 10;
    const where: Record<string, any> = {};

    if (query?.status) where['status'] = query.status;
    if (query?.patientId) {
      where['patient'] = { id: query.patientId };
    }
    if (query?.scheduleDate) where['scheduleDate'] = query.scheduleDate;

    const [data, total] = await this.bookingRepo.findAndCount({
      where: where as any,
      relations: ['diagnostic', 'patient'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return {
      data: data.map((b) => ({
        id: b.id,
        scheduleDate: b.scheduleDate,
        status: b.status,
        notes: b.notes,
        paymentMethod: b.paymentMethod,
        paymentStatus: b.paymentStatus,
        isPaid: b.isPaid,
        transactionId: b.transactionId,
        bankTransactionId: b.bankTransactionId,
        paidAmount: b.paidAmount,
        cancellationReason: b.cancellationReason,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
        diagnostic: {
          id: b.diagnostic?.id,
          test_name: b.diagnostic?.test_name,
          category: b.diagnostic?.category,
        },
        patient: {
          id: (b.patient as any)?.id,
          name: (b.patient as any)?.name,
          phone: (b.patient as any)?.phone,
        },
      })),
      total,
      page,
      limit,
    };
  }

  async cancelBookingWorkflow(
    id: number,
    reason: string,
    adminId: number,
    adminEmail: string,
  ) {
    const booking = await this.bookingRepo.findOne({
      where: { id },
      relations: ['diagnostic', 'patient'],
    });

    if (!booking) throw new NotFoundException('Booking not found');

    booking.status = 'cancelled';
    booking.cancellationReason = reason;
    await this.bookingRepo.save(booking);

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'CANCEL_BOOKING',
      'DiagnosticBooking',
      id,
      { reason },
    );

    return {
      id: booking.id,
      scheduleDate: booking.scheduleDate,
      status: booking.status,
      notes: booking.notes,
      cancellationReason: booking.cancellationReason,
      diagnostic: {
        id: booking.diagnostic?.id,
        test_name: booking.diagnostic?.test_name,
        category: booking.diagnostic?.category,
      },
      patient: {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        id: (booking.patient as any)?.id,
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        name: (booking.patient as any)?.name,
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        phone: (booking.patient as any)?.phone,
      },
    };
  }

  async bulkUpdateBookingStatus(
    ids: number[],
    status: string,
    adminId: number,
    adminEmail: string,
  ) {
    const result = await this.bookingRepo.update(
      { id: ids as any },
      // eslint-disable-next-line
      { status } as any,
    );

    // ✅ Audit log
    await this.auditLogService.logAction(
      adminId,
      adminEmail,
      'BULK_UPDATE_BOOKING_STATUS',
      'DiagnosticBooking',
      undefined,
      { ids, status, count: result.affected },
    );

    return {
      updated: result.affected || 0,
      status,
    };
  }

  // Role Management
  async assignRoleToAdmin(
    adminId: number,
    role: AdminRole,
    currentAdminId: number,
    currentAdminEmail: string,
  ) {
    const admin = await this.adminRepo.findOne({ where: { id: adminId } });
    if (!admin) throw new NotFoundException('Admin not found');

    const oldRole = admin.role;
    admin.role = role;
    await this.adminRepo.save(admin);

    // ✅ Audit log
    await this.auditLogService.logAction(
      currentAdminId,
      currentAdminEmail,
      'ASSIGN_ROLE',
      'Admin',
      adminId,
      { oldRole, newRole: role },
    );

    return {
      id: admin.id,
      name: admin.name,
      email: admin.email,
      phone: admin.phone,
      role: admin.role,
    };
  }

  async getAdminRole(adminId: number) {
    const admin = await this.adminRepo.findOne({ where: { id: adminId } });
    if (!admin) throw new NotFoundException('Admin not found');

    return {
      id: admin.id,
      email: admin.email,
      role: admin.role,
      permissions: ROLE_PERMISSIONS[admin.role] || [],
    };
  }

  async listAllAdminsWithRoles() {
    const admins = await this.adminRepo.find();
    return admins.map((a) => ({
      id: a.id,
      name: a.name,
      email: a.email,
      phone: a.phone,
      role: a.role,
      permissions: ROLE_PERMISSIONS[a.role] || [],
      createdAt: a.createdAt,
      updatedAt: a.updatedAt,
    }));
  }

  getRolePermissions(role: AdminRole) {
    return {
      role,
      permissions: ROLE_PERMISSIONS[role] || [],
    };
  }

  getAllRoles() {
    return Object.entries(AdminRole).map(([key, value]) => ({
      roleKey: key,
      roleName: value,
      permissions: ROLE_PERMISSIONS[value as AdminRole] || [],
    }));
  }

  async getPatientHistory(patientId: number) {
    const patient = await this.userRepo.findOne({ where: { id: patientId } });
    if (!patient) throw new NotFoundException('Patient not found');

    const prescriptions = await this.prescriptionRepo.find({
      where: { patientId },
      order: { createdAt: 'DESC' },
    });

    return prescriptions.map((p) => ({
      id: p.id,
      appointmentId: p.appointmentId,
      patientAge: p.patientAge,
      diagnosis: p.diagnosis,
      medicines: p.medicines ?? [],
      testsSuggested: p.testsSuggested ?? [],
      notes: p.notes,
      createdAt: p.createdAt,
      doctor: p.doctor
        ? {
            id: p.doctor.id,
            name: p.doctor.name,
            specialty: p.doctor.specialty,
            degrees: p.doctor.degrees,
            phone: p.doctor.phone,
          }
        : null,
      patient: {
        id: patient.id,
        name: patient.name,
        phone: patient.phone,
      },
    }));
  }
}
