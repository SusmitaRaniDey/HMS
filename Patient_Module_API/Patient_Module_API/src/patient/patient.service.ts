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
import { AppointmentsService } from 'src/appointments/appointments.service';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { BillingService } from 'src/billing/billing.service';
import { InvoicePdfService } from 'src/common/invoice-pdf.service';
import { SslcommerzVerificationService } from 'src/common/payments/sslcommerz-verification.service';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Repository } from 'typeorm';
import { BookDiagnosticDto } from './dto/book-diagnostic.dto';
import { LoginPatientDto } from './dto/loginPatientDto';
import { RegisterEmailDto } from './dto/registerEmailDto';
import { RegisterPhoneDto } from './dto/registerPhoneDto';

@Injectable()
export class PatientService {
  constructor(
    @InjectRepository(Patients)
    private userRepo: Repository<Patients>,
    @InjectRepository(Appointment)
    private appointmentRepo: Repository<Appointment>,
    @InjectRepository(DiagnosticBooking)
    private bookingRepo: Repository<DiagnosticBooking>,
    @InjectRepository(Diagnostic)
    private diagnosticRepo: Repository<Diagnostic>,
    @InjectRepository(Doctor)
    private doctorRepo: Repository<Doctor>,
    private jwtService: JwtService,
    private configService: ConfigService,
    private appointmentsService: AppointmentsService,
    private paymentVerifier: SslcommerzVerificationService,
    private invoicePdfService: InvoicePdfService,
    private billingService: BillingService,
  ) {}

  async createAdminPatient(input: {
    name: string;
    age: number;
    contactNumber: string;
  }): Promise<Patients> {
    const phone = input.contactNumber.trim();
    const existing = await this.userRepo.findOne({ where: { phone } });
    if (existing) {
      throw new BadRequestException(
        'A registered patient already uses this contact number. Select that patient instead.',
      );
    }

    // The account can be activated later through the normal password recovery flow.
    const password = await bcrypt.hash(
      `${Date.now()}-${Math.random().toString(36)}`,
      10,
    );
    return this.userRepo.save(
      this.userRepo.create({
        name: input.name.trim(),
        age: input.age,
        phone,
        email: '',
        password,
      }),
    );
  }

  // Authentication Methods
  async registerWithEmail(dto: RegisterEmailDto) {
    const existing = await this.userRepo.findOne({
      where: { email: dto.email },
    });
    if (existing) {
      throw new BadRequestException('Email already registered');
    }

    const hash = await bcrypt.hash(dto.password, 10);
    const patient = this.userRepo.create({
      name: dto.name,
      email: dto.email,
      password: hash,
      phone: '',
    });

    const saved = await this.userRepo.save(patient);

    return {
      id: saved.id,
      name: saved.name,
      email: saved.email,
      phone: saved.phone,
    };
  }

  async registerWithPhone(dto: RegisterPhoneDto) {
    const existing = await this.userRepo.findOne({
      where: { phone: dto.phone },
    });
    if (existing) {
      throw new BadRequestException('Phone number already registered');
    }

    const hash = await bcrypt.hash(dto.password, 10);
    const patient = this.userRepo.create({
      name: dto.name,
      phone: dto.phone,
      password: hash,
      email: '',
    });

    const saved = await this.userRepo.save(patient);

    return {
      id: saved.id,
      name: saved.name,
      phone: saved.phone,
      email: saved.email,
    };
  }

  async loginPatient(dto: LoginPatientDto) {
    let patient: Patients | null = null;

    if (dto.email) {
      patient = await this.userRepo
        .createQueryBuilder('patient')
        .addSelect('patient.password')
        .where('patient.email = :email', { email: dto.email })
        .getOne();
    } else if (dto.phone) {
      patient = await this.userRepo
        .createQueryBuilder('patient')
        .addSelect('patient.password')
        .where('patient.phone = :phone', { phone: dto.phone })
        .getOne();
    } else {
      throw new BadRequestException('Email or phone is required');
    }

    if (!patient) {
      throw new NotFoundException('Patient not found');
    }

    const isPasswordMatch = await bcrypt.compare(
      dto.password,
      patient.password,
    );
    if (!isPasswordMatch) {
      throw new UnauthorizedException('Wrong password');
    }

    const token = this.jwtService.sign(
      {
        id: patient.id,
        name: patient.name,
        email: patient.email,
        phone: patient.phone,
      },
      { secret: this.configService.get('ACCESS_TOKEN_SEC') as string },
    );

    return {
      accessToken: token,
      patient: {
        id: patient.id,
        name: patient.name,
        email: patient.email,
        phone: patient.phone,
      },
    };
  }

  // Profile Management
  async getPatientProfile(patientId: number) {
    const patient = await this.userRepo.findOne({ where: { id: patientId } });
    if (!patient) throw new NotFoundException('Patient not found');

    return {
      id: patient.id,
      name: patient.name,
      phone: patient.phone,
      email: patient.email,
      createdAt: patient.createdAt,
    };
  }

  async updatePatientProfile(
    patientId: number,
    dto: { name?: string; phone?: string; email?: string },
  ) {
    const patient = await this.userRepo.findOne({ where: { id: patientId } });
    if (!patient) throw new NotFoundException('Patient not found');

    if (dto.name) patient.name = dto.name;
    if (dto.phone) patient.phone = dto.phone;
    if (dto.email) patient.email = dto.email;

    await this.userRepo.save(patient);
    return {
      id: patient.id,
      name: patient.name,
      phone: patient.phone,
      email: patient.email,
    };
  }

  async updatePassword(
    patientId: number,
    oldPassword: string,
    newPassword: string,
  ) {
    const patient = await this.userRepo
      .createQueryBuilder('patient')
      .addSelect('patient.password')
      .where('patient.id = :id', { id: patientId })
      .getOne();
    if (!patient) throw new NotFoundException('Patient not found');

    const isPasswordMatch = await bcrypt.compare(oldPassword, patient.password);
    if (!isPasswordMatch) {
      throw new BadRequestException('Old password is incorrect');
    }

    patient.password = await bcrypt.hash(newPassword, 10);
    await this.userRepo.save(patient);

    return { message: 'Password updated successfully' };
  }

  // Appointment Management
  async bookAppointment(
    patientId: number,
    dto: {
      doctorId: number;
      date: string;
      type?: string;
      status?: string;
      startTime?: string;
      timeSlot?: string;
      isPaid?: string;
      paymentMethod?: string;
      paymentStatus?: string;
      transactionId?: string;
      bankTransactionId?: string;
      paidAmount?: number;
      appointmentFor?: string;
      otherPatientName?: string;
      otherPatientAge?: number;
      otherPatientGender?: string;
      otherPatientContact?: string;
    },
  ) {
    // Use AppointmentsService which handles all validation and serial number assignment
    return this.appointmentsService.create({
      doctorId: dto.doctorId,
      patientId,
      date: dto.date,
      type: dto.type,
      status: dto.status,
      startTime: dto.startTime,
      timeSlot: dto.timeSlot,
      isPaid: dto.isPaid,
      paymentMethod: dto.paymentMethod,
      paymentStatus: dto.paymentStatus,
      transactionId: dto.transactionId,
      bankTransactionId: dto.bankTransactionId,
      paidAmount: dto.paidAmount,
      appointmentFor: dto.appointmentFor,
      otherPatientName: dto.otherPatientName,
      otherPatientAge: dto.otherPatientAge,
      otherPatientGender: dto.otherPatientGender,
      otherPatientContact: dto.otherPatientContact,
    });
  }

  /**
   * Server-side confirmation for an online (SSLCommerz) appointment
   * payment — see AppointmentsService.confirmOnlinePayment for the
   * verification logic itself.
   */
  async confirmAppointmentPayment(
    appointmentId: number,
    patientId: number,
    data: {
      transactionId: string;
      validationId?: string;
      bankTransactionId?: string;
    },
  ) {
    return this.appointmentsService.confirmOnlinePayment(
      appointmentId,
      patientId,
      data,
      this.paymentVerifier,
    );
  }

  async checkExistingAppointment(
    patientId: number,
    doctorId: number,
    date: string,
  ) {
    const appointment = await this.appointmentRepo.findOne({
      where: {
        patientId,
        doctorId,
        date,
      },
      relations: ['doctor'],
    });

    if (appointment) {
      return {
        exists: true,
        appointment: {
          id: appointment.id,
          doctorId: appointment.doctorId,
          date: appointment.date,
          serialNumber: appointment.serialNumber,
          status: appointment.status,
          doctor: {
            id: appointment.doctor?.id,
            name: appointment.doctor?.name,
            specialty: appointment.doctor?.specialty,
          },
        },
      };
    }

    return {
      exists: false,
      message: 'No appointment found for this doctor on this date',
    };
  }

  async getPatientAppointments(
    patientId: number,
    page: number = 1,
    limit: number = 10,
  ) {
    const [appointments, total] = await this.appointmentRepo.findAndCount({
      where: { patientId },
      relations: ['doctor'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return {
      data: appointments.map((a) => ({
        id: a.id,
        date: a.date,
        serialNumber: a.serialNumber,
        status: a.status,
        type: a.type,
        zoomMeetingId: a.zoomMeetingId,
        zoomJoinUrl: null,
        zoomStartUrl: null,
        zoomPassword: a.zoomPassword,
        meetingStatus: a.meetingStatus,
        startTime: a.startTime,
        prescriptionId: a.prescriptionId,
        cancellationReason: a.cancellationReason,
        isPaid: a.isPaid,
        paymentMethod: a.paymentMethod,
        paymentStatus: a.paymentStatus,
        transactionId: a.transactionId,
        bankTransactionId: a.bankTransactionId,
        paidAmount: a.paidAmount,
        doctor: {
          id: a.doctor?.id,
          name: a.doctor?.name,
          specialty: a.doctor?.specialty,
          fee: a.doctor?.fee,
        },
        createdAt: a.createdAt,
        updatedAt: a.updatedAt,
      })),
      total,
      page,
      limit,
    };
  }

  async getUpcomingAppointments(patientId: number) {
    const appointments = await this.appointmentRepo.find({
      where: { patientId, status: 'confirmed' },
      relations: ['doctor'],
      order: { date: 'ASC', serialNumber: 'ASC' },
    });

    // return appointments;

    return appointments.map((a) => ({
      id: a.id,
      date: a.date,
      serialNumber: a.serialNumber,
      status: a.status,
      type: a.type,
      zoomMeetingId: a.zoomMeetingId,
      zoomJoinUrl: null,
      zoomStartUrl: null,
      zoomPassword: a.zoomPassword,
      meetingStatus: a.meetingStatus,
      startTime: a.startTime,
      prescriptionId: a.prescriptionId,
      doctor: {
        id: a.doctor?.id,
        name: a.doctor?.name,
        specialty: a.doctor?.specialty,
        profilePic: a.doctor?.profilePic,
      },
    }));
  }

  async getAppointmentHistory(
    patientId: number,
    page: number = 1,
    limit: number = 10,
  ) {
    const today = this.getLocalDateString();
    const [appointments, total] = await this.appointmentRepo
      .createQueryBuilder('appointment')
      .leftJoinAndSelect('appointment.doctor', 'doctor')
      .where('appointment.patientId = :patientId', { patientId })
      .andWhere(
        '(appointment.status = :completed OR appointment.date < :today)',
        { completed: 'completed', today },
      )
      .orderBy('appointment.date', 'DESC')
      .addOrderBy('appointment.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      data: appointments.map((a) => ({
        ...a,
        zoomJoinUrl: null,
        zoomStartUrl: null,
      })),
      total,
      page,
      limit,
    };
  }

  async cancelAppointment(
    patientId: number,
    appointmentId: number,
    reason: string,
  ) {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId, patientId },
    });

    if (!appointment) throw new NotFoundException('Appointment not found');
    if (['cancelled', 'completed'].includes(appointment.status)) {
      throw new BadRequestException(
        `A ${appointment.status} appointment cannot be cancelled`,
      );
    }

    appointment.status = 'cancelled';
    appointment.cancellationReason = reason;
    return this.appointmentRepo.save(appointment);
  }

  async getAppointmentMeetingJoinUrl(patientId: number, appointmentId: number) {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId, patientId },
    });

    if (!appointment) throw new NotFoundException('Appointment not found');
    this.validateMeetingAccessDate(appointment);

    if (!appointment.meetingStatus || appointment.meetingStatus === 'scheduled') {
      appointment.meetingStatus = 'started';
      await this.appointmentRepo.save(appointment);
    }

    return {
      meetingUrl: appointment.zoomJoinUrl,
      zoomPassword: appointment.zoomPassword,
    };
  }

  private validateMeetingAccessDate(appointment: Appointment) {
    if (appointment.type !== 'online') {
      throw new BadRequestException('This appointment is not an online meeting.');
    }

    if (!appointment.zoomJoinUrl) {
      throw new BadRequestException('Meeting link is not available yet.');
    }

    const appointmentDate = this.normalizeDate(appointment.date);
    const today = this.getLocalDateString();

    if (today > appointmentDate) {
      throw new BadRequestException(
        'This meeting has ended. The appointment time is over.',
      );
    }

    if (today < appointmentDate) {
      throw new BadRequestException(
        'This meeting is available only on the appointment date.',
      );
    }
  }

  private getLocalDateString(date = new Date()) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private normalizeDate(date: string) {
    return date.includes('T') ? date.split('T')[0] : date;
  }

  // Diagnostic Booking Management
  // One card per item_code: a test panel (e.g. CBC) has many parameter rows
  // in diagnostic_data (Hemoglobin, WBC, Platelet, ...) that share the same
  // item_code/category/test_name/price. Patients should see a single card
  // per panel with a parameter count, not one card per parameter row.
  // Pagination/search operate on the grouped tests, so `total` reflects the
  // number of unique item codes, not raw diagnostic_data rows.
  async getAllDiagnostics(
    page: number = 1,
    limit: number = 20,
    search?: string,
    category?: string,
  ) {
    const diags = await this.diagnosticRepo.find({
      where: { is_active: true },
      order: { id: 'ASC' },
    });

    const groups = new Map<string, Diagnostic[]>();
    for (const d of diags) {
      const key = d.item_code ?? `__id_${d.id}`;
      const existing = groups.get(key);
      if (existing) existing.push(d);
      else groups.set(key, [d]);
    }

    let allGroups = Array.from(groups.values()).map((rows) => {
      const first = rows[0];
      return {
        id: first.id,
        item_code: first.item_code,
        category: first.category,
        test_name: first.test_name,
        price: first.price,
        image: first.image,
        parameterCount: rows.length,
      };
    });

    const q = search?.trim().toLowerCase();
    if (q) {
      allGroups = allGroups.filter(
        (g) =>
          g.test_name?.toLowerCase().includes(q) ||
          g.category?.toLowerCase().includes(q) ||
          g.item_code?.toLowerCase().includes(q),
      );
    }

    const c = category?.trim().toLowerCase();
    if (c) {
      allGroups = allGroups.filter((g) => g.category?.toLowerCase() === c);
    }

    const safePage = page > 0 ? page : 1;
    const safeLimit = limit > 0 ? limit : 20;
    const total = allGroups.length;
    const start = (safePage - 1) * safeLimit;
    const data = allGroups.slice(start, start + safeLimit);

    return { data, total, page: safePage, limit: safeLimit };
  }

  // Every parameter row for a test panel (Parameter/Normal Range/Unit/Notes),
  // used by the Diagnostic Details screen after a patient taps a card.
  async getDiagnosticByItemCode(itemCode: string) {
    const rows = await this.diagnosticRepo.find({
      where: { item_code: itemCode, is_active: true },
      order: { id: 'ASC' },
    });
    if (!rows.length) {
      throw new NotFoundException(
        `No diagnostic test found with item_code "${itemCode}"`,
      );
    }

    const first = rows[0];
    return {
      id: first.id,
      item_code: first.item_code,
      category: first.category,
      test_name: first.test_name,
      price: first.price,
      image: first.image,
      notes: first.notes,
      parameterCount: rows.length,
      parameters: rows.map((r) => ({
        id: r.id,
        parameter: r.parameter,
        normal_range: r.normal_range,
        unit: r.unit,
        notes: r.notes,
      })),
    };
  }

  async getDiagnosticCategories() {
    const rows = await this.diagnosticRepo
      .createQueryBuilder('diag')
      .select('DISTINCT diag.category', 'category')
      .where('diag.is_active = true')
      .orderBy('diag.category', 'ASC')
      .getRawMany<{ category: string }>();
    return rows.map((r) => r.category).filter(Boolean);
  }

  async bookDiagnostic(
    patientId: number,
    dto: BookDiagnosticDto,
    adminCreated = false,
  ) {
    const diagnostic = await this.diagnosticRepo.findOne({
      where: { id: dto.diagnosticId },
    });

    if (!diagnostic) throw new BadRequestException('Diagnostic not found');

    // The diagnostic's own configured price is always authoritative, and a
    // patient-initiated (non-admin) booking always starts pending/unpaid
    // regardless of what the client reports — status can only move to
    // "confirmed" via an admin approving it (see DiagnosticBookingService
    // .approveBooking, which requires 'pending'), and payment can only be
    // marked "paid" through confirmDiagnosticBookingPayment, which
    // independently re-verifies the transaction with SSLCommerz. Without
    // this, a patient could report their own payment as already-succeeded
    // and set status straight to "confirmed", skipping admin review
    // entirely.
    const booking = this.bookingRepo.create({
      diagnostic,
      patient: { id: patientId } as Patients,
      scheduleDate: dto.scheduleDate,
      notes: dto.notes,
      status: adminCreated ? 'confirmed' : 'pending',
      paymentMethod: adminCreated ? 'pay_in_hospital' : dto.paymentMethod,
      paymentStatus: adminCreated ? 'completed' : 'pending',
      isPaid: adminCreated ? 'paid' : 'unpaid',
      transactionId: adminCreated ? undefined : dto.transactionId,
      bankTransactionId: undefined,
      paidAmount: diagnostic.price,
      ...(dto.prescriptionId != null && { prescriptionId: dto.prescriptionId }),
      ...(dto.isPrescribed != null && { isPrescribed: dto.isPrescribed }),
    });

    const saved = await this.bookingRepo.save(booking);

    // Money already changed hands at the counter for this path — same
    // reasoning as AppointmentsService.create's isAdminHospitalPayment
    // branch. `saved.patient`/`saved.diagnostic` are already the full
    // entities assigned above (not a re-fetch), so no extra query needed.
    if (adminCreated) {
      await this.billingService.createFromDiagnosticBooking(saved);
    }

    return saved;
  }

  /**
   * Server-side confirmation for an online (SSLCommerz) diagnostic booking
   * payment — mirrors confirmOnlinePayment on AppointmentsService.
   */
  async confirmDiagnosticBookingPayment(
    bookingId: number,
    patientId: number,
    data: {
      transactionId: string;
      validationId?: string;
      bankTransactionId?: string;
    },
  ) {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId, patient: { id: patientId } },
    });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.paymentStatus === 'completed') return booking;

    await this.paymentVerifier.verify(
      data.validationId,
      data.transactionId,
      Number(booking.paidAmount),
    );

    booking.isPaid = 'paid';
    booking.paymentStatus = 'completed';
    booking.paymentMethod = 'sslcommerz';
    booking.transactionId = data.transactionId;
    if (data.bankTransactionId) booking.bankTransactionId = data.bankTransactionId;
    // A verified online payment auto-confirms the booking (no separate
    // admin review needed, since money already changed hands) — same
    // outcome the client used to request directly, now gated on a real
    // SSLCommerz check instead of the client's say-so.
    if (booking.status === 'pending') {
      booking.status = 'confirmed';
    }
    const saved = await this.bookingRepo.save(booking);
    await this.billingService.createFromDiagnosticBooking(saved);
    return saved;
  }

  async getPatientBookings(
    patientId: number,
    page: number = 1,
    limit: number = 10,
  ) {
    const [bookings, total] = await this.bookingRepo.findAndCount({
      where: { patient: { id: patientId } },
      relations: ['diagnostic'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return {
      data: bookings.map((b) => ({
        id: b.id,
        scheduleDate: b.scheduleDate,
        status: b.status,
        cancellationReason: b.cancellationReason,
        diagnostic: {
          id: b.diagnostic?.id,
          test_name: b.diagnostic?.test_name,
          category: b.diagnostic?.category,
          price: b.diagnostic?.price,
          image: b.diagnostic?.image,
        },
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      })),
      total,
      page,
      limit,
    };
  }

  async getUpcomingBookings(patientId: number) {
    const bookings = await this.bookingRepo.find({
      where: { patient: { id: patientId }, status: 'confirmed' },
      relations: ['diagnostic'],
      order: { scheduleDate: 'ASC' },
    });

    return bookings.map((b) => ({
      id: b.id,
      scheduleDate: b.scheduleDate,
      status: b.status,
      diagnostic: {
        id: b.diagnostic?.id,
        test_name: b.diagnostic?.test_name,
        category: b.diagnostic?.category,
        price: b.diagnostic?.price,
        image: b.diagnostic?.image,
      },
    }));
  }

  async cancelBooking(patientId: number, bookingId: number, reason: string) {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId, patient: { id: patientId } },
    });

    if (!booking) throw new NotFoundException('Booking not found');

    booking.status = 'cancelled';
    booking.cancellationReason = reason;
    return this.bookingRepo.save(booking);
  }

  async getBookingHistory(
    patientId: number,
    page: number = 1,
    limit: number = 10,
  ) {
    const [bookings, total] = await this.bookingRepo.findAndCount({
      where: { patient: { id: patientId }, status: 'completed' },
      relations: ['diagnostic'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { data: bookings, total, page, limit };
  }

  // ============ DOCTOR BROWSING ============
  async getAllDoctors(
    page: number = 1,
    limit: number = 20,
    search?: string,
    specialty?: string,
  ) {
    const queryBuilder = this.doctorRepo.createQueryBuilder('doctor');

    if (search) {
      queryBuilder.where(
        '(doctor.name LIKE :search OR doctor.specialty LIKE :search OR doctor.degrees LIKE :search)',
        { search: `%${search}%` },
      );
    }

    if (specialty) {
      queryBuilder.andWhere('doctor.specialty = :specialty', { specialty });
    }

    const [doctors, total] = await queryBuilder
      .skip((page - 1) * limit)
      .take(limit)
      .orderBy('doctor.name', 'ASC')
      .getManyAndCount();

    return {
      data: doctors.map((doctor) => ({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        degrees: doctor.degrees,
        experience: doctor.experience,
        working_at: doctor.working_at,
        fee: doctor.fee,
        onlineFee: doctor.onlineFee,
        offlineFee: doctor.offlineFee,
        profilePic: doctor.profilePic,
        biography: doctor.biography,
        languages: doctor.languages,
        available_slots: doctor.available_slots,
        workingDays: doctor.workingDays,
        onlineSchedule: doctor.onlineSchedule,
      })),
      total,
      page,
      limit,
    };
  }

  async getDoctorById(doctorId: number) {
    const doctor = await this.doctorRepo.findOne({ where: { id: doctorId } });
    if (!doctor) {
      throw new NotFoundException('Doctor not found');
    }

    return {
      id: doctor.id,
      name: doctor.name,
      specialty: doctor.specialty,
      degrees: doctor.degrees,
      experience: doctor.experience,
      working_at: doctor.working_at,
      fee: doctor.fee,
      onlineFee: doctor.onlineFee,
      offlineFee: doctor.offlineFee,
      profilePic: doctor.profilePic,
      biography: doctor.biography,
      languages: doctor.languages,
      available_slots: doctor.available_slots,
      workingDays: doctor.workingDays,
      onlineSchedule: doctor.onlineSchedule,
    };
  }

  // ─── INVOICE PDF GENERATION ───────────────────────────────────────────────

  async generateAppointmentInvoice(appointmentId: number): Promise<Buffer> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
      relations: ['doctor', 'patient'],
    });
    if (!appointment) throw new NotFoundException('Appointment not found');

    const serviceDetails = [
      {
        label: 'Service',
        value:
          appointment.type === 'online'
            ? 'Online Consultation (Zoom)'
            : 'In-Person Consultation',
      },
      { label: 'Doctor', value: appointment.doctor?.name ?? 'N/A' },
      { label: 'Specialty', value: appointment.doctor?.specialty ?? 'N/A' },
      { label: 'Date', value: appointment.date },
      { label: 'Serial No.', value: `#${appointment.serialNumber ?? 'N/A'}` },
      { label: 'Status', value: (appointment.status ?? 'N/A').toUpperCase() },
    ];

    return this.invoicePdfService.generate({
      invoiceNumber: `APT-${String(appointment.id).padStart(6, '0')}`,
      invoiceFor: 'Doctor Appointment',
      patientName: appointment.patient?.name ?? 'N/A',
      patientPhone: appointment.patient?.phone ?? '',
      patientEmail: appointment.patient?.email ?? '',
      serviceDetails,
      paymentMethod: appointment.paymentMethod ?? 'N/A',
      paymentStatus: appointment.paymentStatus ?? 'N/A',
      isPaid: appointment.isPaid ?? 'unpaid',
      amount: Number(appointment.paidAmount ?? appointment.doctor?.fee ?? 0),
      transactionId: appointment.transactionId,
      bankTransactionId: appointment.bankTransactionId,
      createdAt: appointment.createdAt,
    });
  }

  async generateBookingInvoice(bookingId: number): Promise<Buffer> {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId },
      relations: ['diagnostic', 'patient'],
    });
    if (!booking) throw new NotFoundException('Booking not found');

    const serviceDetails = [
      { label: 'Test', value: booking.diagnostic?.test_name ?? 'N/A' },
      { label: 'Category', value: booking.diagnostic?.category ?? 'N/A' },
      { label: 'Schedule Date', value: booking.scheduleDate },
      { label: 'Status', value: (booking.status ?? 'N/A').toUpperCase() },
    ];

    return this.invoicePdfService.generate({
      invoiceNumber: `DX-${String(booking.id).padStart(6, '0')}`,
      invoiceFor: 'Diagnostic Test Booking',
      patientName: booking.patient?.name ?? 'N/A',
      patientPhone: booking.patient?.phone ?? '',
      patientEmail: booking.patient?.email ?? '',
      serviceDetails,
      paymentMethod: booking.paymentMethod ?? 'N/A',
      paymentStatus: booking.paymentStatus ?? 'N/A',
      isPaid: booking.isPaid ?? 'unpaid',
      amount: Number(booking.paidAmount ?? booking.diagnostic?.price ?? 0),
      transactionId: booking.transactionId,
      bankTransactionId: booking.bankTransactionId,
      createdAt: booking.createdAt,
    });
  }

}
