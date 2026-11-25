import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { BillingService } from 'src/billing/billing.service';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { ZoomService } from 'src/zoom/zoom.service';
import { DataSource, Repository } from 'typeorm';
import { SetEmergencyAvailabilityDto } from './dto/emergency-availability.dto';
import { EmergencyAvailability } from './entities/emergency-availability.entity';
import {
  CompleteEmergencyPaymentDto,
  EmergencyPaymentCallbackDto,
} from './dto/emergency-payment.dto';

@Injectable()
export class EmergencyConsultationService {
  constructor(
    @InjectRepository(EmergencyAvailability)
    private readonly availabilityRepo: Repository<EmergencyAvailability>,
    @InjectRepository(Appointment)
    private readonly appointmentRepo: Repository<Appointment>,
    @InjectRepository(Doctor)
    private readonly doctorRepo: Repository<Doctor>,
    private readonly dataSource: DataSource,
    private readonly zoomService: ZoomService,
    private readonly billingService: BillingService,
  ) {}

  private get additionalEmergencyFee() {
    const value = Number(process.env.ADDITIONAL_EMERGENCY_FEE ?? 0);
    return Number.isFinite(value) && value > 0 ? value : 0;
  }

  private transactionId() {
    return `EMG_${Date.now()}_${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
  }

  private validateWindow(from: Date, until: Date) {
    if (
      Number.isNaN(from.getTime()) ||
      Number.isNaN(until.getTime()) ||
      until <= from
    ) {
      throw new BadRequestException(
        'Available Until must be later than Available From',
      );
    }
  }

  async setAvailability(
    doctorId: number,
    dto: SetEmergencyAvailabilityDto,
    isAdmin = false,
  ) {
    const doctor = await this.doctorRepo.findOne({ where: { id: doctorId } });
    if (!doctor) throw new NotFoundException('Doctor not found');
    const availableFrom = new Date(dto.availableFrom);
    const availableUntil = new Date(dto.availableUntil);
    this.validateWindow(availableFrom, availableUntil);

    let availability = await this.availabilityRepo.findOne({
      where: { doctorId },
    });
    availability ??= this.availabilityRepo.create({ doctorId });
    availability.availableFrom = availableFrom;
    availability.availableUntil = availableUntil;
    availability.isEnabled = dto.isEnabled ?? true;
    if (isAdmin) {
      availability.enabledByAdmin = dto.enabledByAdmin ?? true;
    } else if (!availability.enabledByAdmin) {
      throw new BadRequestException(
        'Emergency consultation is disabled by an administrator',
      );
    }
    if (dto.emergencyFee !== undefined)
      availability.emergencyFee = dto.emergencyFee;
    return this.availabilityRepo.save(availability);
  }

  async getDoctorAvailability(doctorId: number) {
    return (
      (await this.availabilityRepo.findOne({ where: { doctorId } })) ?? {
        doctorId,
        isEnabled: false,
        enabledByAdmin: true,
      }
    );
  }

  async turnOff(doctorId: number, isAdmin = false) {
    const availability = await this.availabilityRepo.findOne({
      where: { doctorId },
    });
    if (!availability) throw new NotFoundException('Availability not found');
    availability.isEnabled = false;
    if (isAdmin) availability.enabledByAdmin = false;
    return this.availabilityRepo.save(availability);
  }

  async listAvailable() {
    const now = new Date();
    const rows = await this.availabilityRepo
      .createQueryBuilder('availability')
      .leftJoinAndSelect('availability.doctor', 'doctor')
      .where('availability.isEnabled = :enabled', { enabled: true })
      .andWhere('availability.enabledByAdmin = :enabled', { enabled: true })
      .andWhere('availability.availableFrom <= :now', { now })
      .andWhere('availability.availableUntil > :now', { now })
      .andWhere(
        `NOT EXISTS (
        SELECT 1 FROM appointment appointment
        WHERE appointment.doctorId = availability.doctorId
        AND appointment.isEmergency = 1
        AND appointment.status = 'confirmed'
        AND (appointment.meetingStatus IS NULL OR appointment.meetingStatus != 'ended')
      )`,
      )
      .orderBy('availability.availableUntil', 'ASC')
      .getMany();

    return rows.map((row) => ({
      id: row.id,
      doctorId: row.doctorId,
      name: row.doctor.name,
      department: row.doctor.specialty,
      experience: row.doctor.experience,
      profilePic: row.doctor.profilePic,
      emergencyFee:
        row.emergencyFee ?? row.doctor.onlineFee ?? row.doctor.fee ?? 0,
      additionalEmergencyFee: this.additionalEmergencyFee,
      availableFrom: row.availableFrom,
      availableUntil: row.availableUntil,
      onlineStatus: 'online',
    }));
  }

  async initiatePayment(patientId: number, doctorId: number) {
    const availability = await this.getBookableAvailability(doctorId);
    const patient = await this.dataSource.getRepository(Patients).findOne({
      where: { id: patientId },
    });
    if (!patient) throw new NotFoundException('Patient not found');

    const doctorFee = Number(
      availability.emergencyFee ??
        availability.doctor.onlineFee ??
        availability.doctor.fee ??
        0,
    );
    const totalAmount = doctorFee + this.additionalEmergencyFee;
    if (totalAmount <= 0) {
      throw new BadRequestException(
        'Emergency consultation fee is not configured',
      );
    }

    const transactionId = this.transactionId();
    const now = new Date();
    const appointment = await this.appointmentRepo.save(
      this.appointmentRepo.create({
        doctorId,
        patientId,
        date: now.toISOString().slice(0, 10),
        startTime: now.toISOString(),
        timeSlot: now.toTimeString().slice(0, 5),
        type: 'online',
        status: 'pending',
        isEmergency: true,
        emergencyAvailabilityId: availability.id,
        isPaid: 'unpaid',
        paymentMethod: 'sslcommerz',
        paymentStatus: 'pending',
        transactionId,
        paidAmount: totalAmount,
      }),
    );

    return {
      appointmentId: appointment.id,
      transactionId,
      amount: totalAmount,
      currency: 'BDT',
      doctorFee,
      additionalEmergencyFee: this.additionalEmergencyFee,
      productName: `Emergency Consultation with ${availability.doctor.name}`,
    };
  }

  async completePayment(patientId: number, dto: CompleteEmergencyPaymentDto) {
    const appointment = await this.findPaymentIntent(
      dto.transactionId,
      patientId,
    );
    if (appointment.paymentStatus === 'completed') {
      return this.getBooking(patientId, appointment.id);
    }

    await this.assertGatewayPayment(
      dto.validationId,
      dto.transactionId,
      appointment,
    );
    appointment.isPaid = 'paid';
    appointment.paymentStatus = 'completed';
    appointment.paymentMethod = dto.paymentMethod || 'sslcommerz';
    if (dto.bankTransactionId) {
      appointment.bankTransactionId = dto.bankTransactionId;
    }
    appointment.status = 'confirmed';
    await this.appointmentRepo.save(appointment);

    try {
      await this.zoomService.createMeeting({
        appointmentId: appointment.id,
        startTime: appointment.startTime,
        duration: 30,
        topic: 'Emergency doctor consultation',
        requireRealMeeting: true,
      });
    } catch (error) {
      appointment.status = 'pending';
      await this.appointmentRepo.save(appointment);
      throw error;
    }

    await this.billingService.createFromAppointment(appointment);

    return this.getBooking(patientId, appointment.id);
  }

  async failPayment(patientId: number, transactionId: string) {
    return this.markPayment(transactionId, 'failed', patientId);
  }

  async cancelPayment(patientId: number, transactionId: string) {
    return this.markPayment(transactionId, 'cancelled', patientId);
  }

  async handleGatewayCallback(
    status: 'success' | 'failed' | 'cancelled',
    dto: EmergencyPaymentCallbackDto,
  ) {
    if (!dto.tran_id) throw new BadRequestException('Missing transaction ID');
    const appointment = await this.findPaymentIntent(dto.tran_id);
    if (status !== 'success') return this.markPayment(dto.tran_id, status);
    return this.completePayment(appointment.patientId, {
      transactionId: dto.tran_id,
      validationId: dto.val_id,
      bankTransactionId: dto.bank_tran_id,
      paymentMethod: dto.card_type,
    });
  }

  async getBooking(patientId: number, appointmentId: number) {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId, patientId, isEmergency: true },
      relations: ['doctor'],
    });
    if (!appointment)
      throw new NotFoundException('Emergency booking not found');
    return {
      ...appointment,
      consultationType: 'Emergency',
      bookingStatus: appointment.status,
      totalAmount: Number(appointment.paidAmount ?? 0),
      emergencyFee:
        Number(appointment.paidAmount ?? 0) - this.additionalEmergencyFee,
      additionalEmergencyFee: this.additionalEmergencyFee,
    };
  }

  private async getBookableAvailability(doctorId: number) {
    const availability = await this.availabilityRepo.findOne({
      where: { doctorId },
      relations: ['doctor'],
    });
    const now = new Date();
    if (
      !availability ||
      !availability.isEnabled ||
      !availability.enabledByAdmin ||
      availability.availableFrom > now ||
      availability.availableUntil <= now
    ) {
      throw new BadRequestException(
        'This doctor is no longer available for emergency consultation',
      );
    }
    const engaged = await this.appointmentRepo
      .createQueryBuilder('appointment')
      .where('appointment.doctorId = :doctorId', { doctorId })
      .andWhere('appointment.isEmergency = :emergency', { emergency: true })
      .andWhere('appointment.status IN (:...statuses)', {
        statuses: ['confirmed'],
      })
      .andWhere(
        '(appointment.meetingStatus IS NULL OR appointment.meetingStatus != :ended)',
        { ended: 'ended' },
      )
      .getOne();
    if (engaged)
      throw new ConflictException('This doctor is already in consultation');
    return availability;
  }

  private async findPaymentIntent(transactionId: string, patientId?: number) {
    const where: Record<string, unknown> = {
      transactionId,
      isEmergency: true,
    };
    if (patientId !== undefined) where.patientId = patientId;
    const appointment = await this.appointmentRepo.findOne({ where });
    if (!appointment)
      throw new NotFoundException('Emergency payment not found');
    return appointment;
  }

  private async markPayment(
    transactionId: string,
    status: 'failed' | 'cancelled',
    patientId?: number,
  ) {
    const appointment = await this.findPaymentIntent(transactionId, patientId);
    if (appointment.paymentStatus !== 'completed') {
      appointment.paymentStatus = status;
      appointment.status = 'cancelled';
      appointment.isPaid = 'unpaid';
      await this.appointmentRepo.save(appointment);
    }
    return {
      appointmentId: appointment.id,
      transactionId,
      paymentStatus: status,
    };
  }

  private async assertGatewayPayment(
    validationId: string | undefined,
    transactionId: string,
    appointment: Appointment,
  ) {
    const storeId = process.env.SSLCOMMERZ_STORE_ID;
    const storePassword = process.env.SSLCOMMERZ_STORE_PASSWORD;
    // The mobile SDK already returns a VALID/VALIDATED result in sandbox and
    // development. Production must always validate val_id server-side.
    if (process.env.NODE_ENV !== 'production') return;
    if (!validationId || !storeId || !storePassword) {
      throw new BadRequestException('Payment validation is not configured');
    }
    const sandbox = process.env.SSLCOMMERZ_SANDBOX !== 'false';
    const host = sandbox
      ? 'sandbox.sslcommerz.com'
      : 'securepay.sslcommerz.com';
    const url = new URL(
      `https://${host}/validator/api/validationserverAPI.php`,
    );
    url.searchParams.set('val_id', validationId);
    url.searchParams.set('store_id', storeId);
    url.searchParams.set('store_passwd', storePassword);
    url.searchParams.set('format', 'json');
    const response = await fetch(url);
    if (!response.ok)
      throw new BadRequestException('Unable to validate payment');
    const result = (await response.json()) as Record<string, unknown>;
    const valid = ['VALID', 'VALIDATED'].includes(String(result.status));
    const amountMatches =
      Math.abs(Number(result.amount) - Number(appointment.paidAmount)) < 0.01;
    if (!valid || !amountMatches || String(result.tran_id) !== transactionId) {
      throw new BadRequestException('Invalid SSLCommerz payment response');
    }
  }

  async dashboard() {
    const [availableDoctors, emergencyAppointments] = await Promise.all([
      this.listAvailable(),
      this.appointmentRepo.find({
        where: { isEmergency: true },
        order: { createdAt: 'DESC' },
      }),
    ]);
    return {
      availableDoctors,
      active: emergencyAppointments.filter(
        (a) => a.status === 'confirmed' && a.meetingStatus !== 'ended',
      ),
      completed: emergencyAppointments.filter(
        (a) => a.status === 'completed' || a.meetingStatus === 'ended',
      ),
      cancelled: emergencyAppointments.filter((a) => a.status === 'cancelled'),
      history: emergencyAppointments,
    };
  }

  async listAllAvailability() {
    return this.availabilityRepo.find({ order: { updatedAt: 'DESC' } });
  }
}
