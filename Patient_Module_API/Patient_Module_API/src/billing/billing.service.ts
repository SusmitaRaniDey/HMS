import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { InvoicePdfService } from 'src/common/invoice-pdf.service';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Repository } from 'typeorm';
import { BillingFilterDto } from './dto/billing-filter.dto';
import { CreateBillingDto } from './dto/create-billing.dto';
import { Billing, BillType } from './entities/billing.entity';

function isDuplicateKeyError(err: unknown): boolean {
  const code = (err as { code?: string; driverError?: { code?: string } })
    ?.code;
  const driverCode = (err as { driverError?: { code?: string } })
    ?.driverError?.code;
  return code === 'ER_DUP_ENTRY' || driverCode === 'ER_DUP_ENTRY';
}

@Injectable()
export class BillingService {
  private readonly logger = new Logger(BillingService.name);

  constructor(
    @InjectRepository(Billing)
    private billingRepo: Repository<Billing>,
    @InjectRepository(Patients)
    private patientRepo: Repository<Patients>,
    private invoicePdfService: InvoicePdfService,
  ) {}

  /**
   * Best-effort, idempotent: called from the payment-confirmation paths in
   * AppointmentsService and EmergencyConsultationService. Never throws —
   * a billing failure must not break the appointment/payment flow that
   * triggered it.
   */
  async createFromAppointment(appointment: Appointment): Promise<Billing | null> {
    const isConfirmedPaid =
      appointment.isPaid === 'paid' && appointment.paymentStatus === 'completed';
    if (!isConfirmedPaid) return null;

    const existing = await this.billingRepo.findOne({
      where: { appointmentId: appointment.id },
    });
    if (existing) return existing;

    const billType = appointment.isEmergency
      ? BillType.EMERGENCY_CONSULTATION
      : appointment.type === 'online'
        ? BillType.ONLINE_CONSULTATION
        : BillType.APPOINTMENT;

    const amount = Number(appointment.paidAmount ?? 0);
    const description = appointment.isEmergency
      ? 'Emergency doctor consultation'
      : appointment.type === 'online'
        ? 'Online doctor consultation'
        : 'Doctor appointment';

    try {
      const saved = await this.billingRepo.save(
        this.billingRepo.create({
          patientId: appointment.patientId,
          appointmentId: appointment.id,
          diagnosticBookingId: null,
          billType,
          subtotal: amount,
          discount: 0,
          tax: 0,
          totalAmount: amount,
          paymentMethod: appointment.paymentMethod ?? 'unknown',
          paymentStatus: appointment.paymentStatus ?? 'completed',
          transactionId: appointment.transactionId ?? null,
          currency: 'BDT',
          invoiceDate: new Date(),
          description,
        }),
      );
      return this.assignInvoiceNumber(saved);
    } catch (err) {
      if (isDuplicateKeyError(err)) {
        const raced = await this.billingRepo.findOne({
          where: { appointmentId: appointment.id },
        });
        if (raced) return raced;
      }
      this.logger.error(
        `Failed to create billing record for appointment ${appointment.id}`,
        err instanceof Error ? err.stack : String(err),
      );
      return null;
    }
  }

  async createFromDiagnosticBooking(
    booking: DiagnosticBooking,
  ): Promise<Billing | null> {
    const isConfirmedPaid =
      booking.isPaid === 'paid' && booking.paymentStatus === 'completed';
    if (!isConfirmedPaid) return null;

    const existing = await this.billingRepo.findOne({
      where: { diagnosticBookingId: booking.id },
    });
    if (existing) return existing;

    const patientId = booking.patient?.id;
    if (!patientId) {
      this.logger.error(
        `Diagnostic booking ${booking.id} has no loaded patient relation; skipping billing`,
      );
      return null;
    }

    const amount = Number(booking.paidAmount ?? booking.diagnostic?.price ?? 0);

    try {
      const saved = await this.billingRepo.save(
        this.billingRepo.create({
          patientId,
          appointmentId: null,
          diagnosticBookingId: booking.id,
          billType: BillType.DIAGNOSTIC_BOOKING,
          subtotal: amount,
          discount: 0,
          tax: 0,
          totalAmount: amount,
          paymentMethod: booking.paymentMethod ?? 'unknown',
          paymentStatus: booking.paymentStatus ?? 'completed',
          transactionId: booking.transactionId ?? null,
          currency: 'BDT',
          invoiceDate: new Date(),
          description: booking.diagnostic?.test_name
            ? `Diagnostic booking: ${booking.diagnostic.test_name}`
            : 'Diagnostic booking',
        }),
      );
      return this.assignInvoiceNumber(saved);
    } catch (err) {
      if (isDuplicateKeyError(err)) {
        const raced = await this.billingRepo.findOne({
          where: { diagnosticBookingId: booking.id },
        });
        if (raced) return raced;
      }
      this.logger.error(
        `Failed to create billing record for diagnostic booking ${booking.id}`,
        err instanceof Error ? err.stack : String(err),
      );
      return null;
    }
  }

  private async assignInvoiceNumber(billing: Billing): Promise<Billing> {
    const invoiceNumber = `INV-${String(billing.id).padStart(6, '0')}`;
    await this.billingRepo.update(billing.id, { invoiceNumber });
    billing.invoiceNumber = invoiceNumber;
    return billing;
  }

  /** Manual/admin creation path — for bill types with no automatic source. */
  async create(dto: CreateBillingDto): Promise<Billing> {
    const patient = await this.patientRepo.findOne({
      where: { id: dto.patientId },
    });
    if (!patient) throw new NotFoundException('Patient not found');

    const discount = dto.discount ?? 0;
    const tax = dto.tax ?? 0;
    const subtotal = dto.totalAmount - tax + discount;

    const saved = await this.billingRepo.save(
      this.billingRepo.create({
        patientId: dto.patientId,
        appointmentId: null,
        diagnosticBookingId: null,
        billType: dto.billType,
        subtotal,
        discount,
        tax,
        totalAmount: dto.totalAmount,
        paymentMethod: dto.paymentMethod,
        paymentStatus: dto.paymentStatus ?? 'completed',
        transactionId: dto.transactionId ?? null,
        currency: dto.currency ?? 'BDT',
        invoiceDate: new Date(),
        description: dto.description ?? null,
      }),
    );
    return this.assignInvoiceNumber(saved);
  }

  async findAllPaginated(filter: BillingFilterDto) {
    const page = filter.page && filter.page > 0 ? filter.page : 1;
    const limit = filter.limit && filter.limit > 0 ? filter.limit : 20;

    const qb = this.billingRepo
      .createQueryBuilder('billing')
      .leftJoinAndSelect('billing.patient', 'patient');

    if (filter.billType) {
      qb.andWhere('billing.billType = :billType', { billType: filter.billType });
    }
    if (filter.paymentStatus) {
      qb.andWhere('billing.paymentStatus = :paymentStatus', {
        paymentStatus: filter.paymentStatus,
      });
    }
    if (filter.dateFrom) {
      qb.andWhere('billing.invoiceDate >= :dateFrom', {
        dateFrom: filter.dateFrom,
      });
    }
    if (filter.dateTo) {
      qb.andWhere('billing.invoiceDate <= :dateTo', { dateTo: filter.dateTo });
    }
    if (filter.search) {
      qb.andWhere(
        '(billing.invoiceNumber LIKE :search OR patient.name LIKE :search)',
        { search: `%${filter.search}%` },
      );
    }

    const sortBy = filter.sortBy ?? 'invoiceDate';
    const sortOrder = filter.sortOrder ?? 'DESC';
    qb.orderBy(`billing.${sortBy}`, sortOrder);

    qb.skip((page - 1) * limit).take(limit);

    const [data, total] = await qb.getManyAndCount();
    return { data, total, page, limit };
  }

  async findOne(id: number): Promise<Billing> {
    const billing = await this.billingRepo.findOne({
      where: { id },
      relations: ['patient', 'appointment', 'appointment.doctor', 'diagnosticBooking', 'diagnosticBooking.diagnostic'],
    });
    if (!billing) throw new NotFoundException('Billing record not found');
    return billing;
  }

  async findByInvoiceNumber(invoiceNumber: string): Promise<Billing> {
    const billing = await this.billingRepo.findOne({
      where: { invoiceNumber },
      relations: ['patient', 'appointment', 'appointment.doctor', 'diagnosticBooking', 'diagnosticBooking.diagnostic'],
    });
    if (!billing) throw new NotFoundException('Billing record not found');
    return billing;
  }

  findByPatient(patientId: number) {
    return this.billingRepo.find({
      where: { patientId },
      order: { invoiceDate: 'DESC' },
    });
  }

  async generateInvoicePdf(id: number): Promise<Buffer> {
    const billing = await this.findOne(id);

    const serviceDetails: { label: string; value: string }[] = [
      { label: 'Bill Type', value: this.billTypeLabel(billing.billType) },
    ];
    if (billing.appointment) {
      serviceDetails.push(
        { label: 'Doctor', value: billing.appointment.doctor?.name ?? 'N/A' },
        { label: 'Date', value: billing.appointment.date },
      );
    }
    if (billing.diagnosticBooking) {
      serviceDetails.push(
        {
          label: 'Test',
          value: billing.diagnosticBooking.diagnostic?.test_name ?? 'N/A',
        },
        { label: 'Schedule Date', value: billing.diagnosticBooking.scheduleDate },
      );
    }
    if (billing.description) {
      serviceDetails.push({ label: 'Description', value: billing.description });
    }
    serviceDetails.push(
      { label: 'Subtotal', value: `BDT ${Number(billing.subtotal).toFixed(0)}` },
      { label: 'Discount', value: `BDT ${Number(billing.discount).toFixed(0)}` },
      { label: 'Tax', value: `BDT ${Number(billing.tax).toFixed(0)}` },
    );

    return this.invoicePdfService.generate({
      invoiceNumber: billing.invoiceNumber ?? `INV-${String(billing.id).padStart(6, '0')}`,
      invoiceFor: this.billTypeLabel(billing.billType),
      patientName: billing.patient?.name ?? 'N/A',
      patientPhone: billing.patient?.phone ?? '',
      patientEmail: billing.patient?.email ?? '',
      serviceDetails,
      paymentMethod: billing.paymentMethod,
      paymentStatus: billing.paymentStatus,
      isPaid: billing.paymentStatus === 'completed' ? 'paid' : 'unpaid',
      amount: Number(billing.totalAmount),
      transactionId: billing.transactionId,
      createdAt: billing.invoiceDate,
    });
  }

  private billTypeLabel(billType: string): string {
    switch (billType) {
      case BillType.APPOINTMENT:
        return 'Doctor Appointment';
      case BillType.ONLINE_CONSULTATION:
        return 'Online Doctor Consultation';
      case BillType.EMERGENCY_CONSULTATION:
        return 'Emergency Doctor Consultation';
      case BillType.DIAGNOSTIC_BOOKING:
        return 'Diagnostic Booking';
      default:
        return billType;
    }
  }
}
