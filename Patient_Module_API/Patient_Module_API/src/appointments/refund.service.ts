import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Patients } from 'src/patient/entities/patient.entity';
import { Repository } from 'typeorm';
import {
  AdminInitiateRefundDto,
  CreateRefundRequestDto,
  ProcessRefundDto,
  RejectRefundDto,
  RefundFilterDto,
} from './dto/refund-request.dto';
import { Appointment } from './entities/appointments.entity';
import {
  RefundInitiator,
  RefundReason,
  RefundRequest,
  RefundStatus,
} from './entities/refund-request.entity';

@Injectable()
export class RefundService {
  constructor(
    @InjectRepository(RefundRequest)
    private refundRepo: Repository<RefundRequest>,

    @InjectRepository(Appointment)
    private appointmentRepo: Repository<Appointment>,

    @InjectRepository(Patients)
    private patientRepo: Repository<Patients>,
  ) {}

  async createForPatient(patientId: number, dto: CreateRefundRequestDto) {
    const appointmentId = dto.appointmentId ?? dto.appointment_id;
    const refundToAccount = dto.refundToAccount ?? dto.refund_to_account;
    if (!appointmentId || !refundToAccount) {
      throw new BadRequestException('appointmentId and refundToAccount are required');
    }
    const appointment = await this.getEligibleAppointment(
      appointmentId,
      patientId,
      dto.reason,
    );

    return this.createRefundRequest({
      appointment,
      reason: dto.reason,
      patientNote: dto.patientNote,
      refundToAccount,
      initiatedBy: RefundInitiator.PATIENT,
    });
  }

  async adminInitiate(
    appointmentId: number,
    adminId: number,
    dto: AdminInitiateRefundDto,
  ) {
    const refundToAccount = dto.refundToAccount ?? dto.refund_to_account;
    if (!refundToAccount) {
      throw new BadRequestException('refundToAccount is required');
    }
    const appointment = await this.getEligibleAppointment(
      appointmentId,
      undefined,
      dto.reason,
    );

    const refund = await this.createRefundRequest({
      appointment,
      reason: dto.reason,
      patientNote: dto.patientNote,
      refundToAccount,
      initiatedBy: RefundInitiator.ADMIN,
      processedBy: adminId,
    });

    await this.notifyPatient(
      appointment.patientId,
      'Refund requested',
      'A refund request has been initiated for your appointment.',
      'refund_requested',
    );

    return refund;
  }

  findMine(patientId: number) {
    return this.refundRepo.find({
      where: { patientId },
      order: { requestedAt: 'DESC' },
    });
  }

  async findByAppointmentForPatient(appointmentId: number, patientId: number) {
    const refund = await this.refundRepo.findOne({
      where: { appointmentId, patientId },
    });
    return refund ?? { exists: false };
  }

  findAll(filter?: RefundFilterDto) {
    return this.refundRepo.find({
      where: filter?.status ? { refundStatus: filter.status } : {},
      order: { requestedAt: 'DESC' },
    });
  }

  async markProcessing(id: number, adminId: number) {
    const refund = await this.getRefund(id);
    if (refund.refundStatus !== RefundStatus.PENDING) {
      throw new BadRequestException('Only pending refunds can be processed');
    }

    refund.refundStatus = RefundStatus.PROCESSING;
    refund.processedBy = adminId;
    const saved = await this.refundRepo.save(refund);

    await this.notifyPatient(
      refund.patientId,
      'Refund processing',
      'Your refund request is now being processed.',
      'refund_processing',
    );

    return saved;
  }

  async process(id: number, adminId: number, dto: ProcessRefundDto) {
    const refundedAmount = dto.refundedAmount ?? dto.refunded_amount;
    const refundTransactionId =
      dto.refundTransactionId ?? dto.refund_transaction_id;
    if (refundedAmount === undefined || !refundTransactionId) {
      throw new BadRequestException(
        'refundedAmount and refundTransactionId are required',
      );
    }
    const refund = await this.getRefund(id);
    if (
      ![RefundStatus.PENDING, RefundStatus.PROCESSING].includes(
        refund.refundStatus,
      )
    ) {
      throw new BadRequestException('This refund cannot be processed');
    }
    if (Number(refundedAmount) <= 0) {
      throw new BadRequestException('refundedAmount must be greater than 0');
    }
    if (Number(refundedAmount) > Number(refund.originalAmount)) {
      throw new BadRequestException(
        `refundedAmount cannot exceed the original payment amount (${refund.originalAmount})`,
      );
    }

    refund.refundStatus = RefundStatus.REFUNDED;
    refund.refundedAmount = refundedAmount;
    refund.refundTransactionId = refundTransactionId;
    refund.processedBy = adminId;
    refund.processedAt = new Date();

    await this.appointmentRepo.update(refund.appointmentId, {
      status: 'cancelled',
      paymentStatus: 'unpaid',
      isPaid: 'unpaid',
    } as any);

    const saved = await this.refundRepo.save(refund);
    await this.notifyPatient(
      refund.patientId,
      'Refund completed',
      'Your refund has been processed successfully.',
      'refund_completed',
    );

    return saved;
  }

  async reject(id: number, adminId: number, dto: RejectRefundDto) {
    const rejectionReason = dto.rejectionReason ?? dto.rejection_reason;
    if (!rejectionReason) {
      throw new BadRequestException('rejectionReason is required');
    }
    const refund = await this.getRefund(id);
    if (refund.refundStatus === RefundStatus.REFUNDED) {
      throw new BadRequestException('Refunded requests cannot be rejected');
    }

    refund.refundStatus = RefundStatus.REJECTED;
    refund.rejectionReason = rejectionReason;
    refund.processedBy = adminId;
    refund.processedAt = new Date();

    const saved = await this.refundRepo.save(refund);
    await this.notifyPatient(
      refund.patientId,
      'Refund rejected',
      `Your refund request was rejected. Reason: ${rejectionReason}`,
      'refund_rejected',
    );

    return saved;
  }

  private async createRefundRequest(data: {
    appointment: Appointment;
    reason: RefundReason;
    patientNote?: string;
    refundToAccount: string;
    initiatedBy: RefundInitiator;
    processedBy?: number;
  }) {
    const duplicate = await this.refundRepo.findOne({
      where: { appointmentId: data.appointment.id },
    });
    if (duplicate) {
      throw new BadRequestException(
        'A refund request already exists for this appointment',
      );
    }

    const refund = this.refundRepo.create({
      appointmentId: data.appointment.id,
      patientId: data.appointment.patientId,
      reason: data.reason,
      patientNote: data.patientNote,
      refundStatus: RefundStatus.PENDING,
      paymentMethod: data.appointment.paymentMethod,
      originalAmount: data.appointment.paidAmount,
      refundToAccount: data.refundToAccount,
      initiatedBy: data.initiatedBy,
      processedBy: data.processedBy,
    });

    const saved = await this.refundRepo.save(refund);
    await this.notifyPatient(
      data.appointment.patientId,
      'Refund requested',
      'Your refund request has been submitted.',
      'refund_requested',
    );

    return saved;
  }

  private async getRefund(id: number) {
    const refund = await this.refundRepo.findOne({ where: { id } });
    if (!refund) throw new NotFoundException('Refund request not found');
    return refund;
  }

  private async getEligibleAppointment(
    appointmentId: number,
    patientId: number | undefined,
    reason: RefundReason,
  ) {
    const appointment = await this.appointmentRepo.findOne({
      where: patientId ? { id: appointmentId, patientId } : { id: appointmentId },
    });
    if (!appointment) throw new NotFoundException('Appointment not found');

    const isPaid =
      appointment.isPaid?.toLowerCase() === 'paid' ||
      ['paid', 'completed'].includes(
        appointment.paymentStatus?.toLowerCase() ?? '',
      );
    if (!isPaid) {
      throw new BadRequestException('Only paid appointments can be refunded');
    }

    if (!this.meetsReasonEligibility(appointment, reason)) {
      throw new BadRequestException(
        'Appointment is not eligible for the selected refund reason',
      );
    }

    return appointment;
  }

  private meetsReasonEligibility(
    appointment: Appointment,
    reason: RefundReason,
  ) {
    const today = new Date().toISOString().split('T')[0];

    if (reason === RefundReason.PATIENT_CANCELLED) {
      return appointment.status === 'cancelled' && appointment.date >= today;
    }

    if (reason === RefundReason.DOCTOR_NO_SHOW) {
      return appointment.type === 'online' && appointment.meetingStatus !== 'ended';
    }

    if (reason === RefundReason.NO_CONSULTATION) {
      return appointment.status !== 'completed' && !appointment.prescriptionId;
    }

    return false;
  }

  private async notifyPatient(
    patientId: number,
    title: string,
    body: string,
    type: string,
  ) {
    const patient = await this.patientRepo.findOne({ where: { id: patientId } });
    const fcmToken = (patient as any)?.fcmToken;
    if (!fcmToken || !process.env.FCM_SERVER_KEY) return;

    await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${process.env.FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: { title, body },
        data: { type },
      }),
    }).catch(() => {});
  }
}
