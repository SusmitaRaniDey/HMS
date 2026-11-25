import { Patients } from 'src/patient/entities/patient.entity';
import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Appointment } from './appointments.entity';

export enum RefundReason {
  PATIENT_CANCELLED = 'patient_cancelled',
  DOCTOR_NO_SHOW = 'doctor_no_show',
  NO_CONSULTATION = 'no_consultation',
}

export enum RefundStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  REFUNDED = 'refunded',
  REJECTED = 'rejected',
}

export enum RefundInitiator {
  PATIENT = 'patient',
  ADMIN = 'admin',
}

@Entity('refund_requests')
export class RefundRequest {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Appointment, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'appointment_id' })
  appointment: Appointment;

  @Column({ name: 'appointment_id', unique: true })
  appointmentId: number;

  @ManyToOne(() => Patients, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: Patients;

  @Column({ name: 'patient_id' })
  patientId: number;

  @Column({ type: 'enum', enum: RefundReason })
  reason: RefundReason;

  @Column({ name: 'patient_note', type: 'text', nullable: true })
  patientNote: string;

  @Column({
    name: 'refund_status',
    type: 'enum',
    enum: RefundStatus,
    default: RefundStatus.PENDING,
  })
  refundStatus: RefundStatus;

  @Column({ name: 'payment_method', nullable: true })
  paymentMethod: string;

  @Column({
    name: 'original_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  originalAmount: number;

  @Column({
    name: 'refunded_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  refundedAmount: number;

  @Column({ name: 'refund_to_account' })
  refundToAccount: string;

  @Column({ name: 'refund_transaction_id', nullable: true })
  refundTransactionId: string;

  @Column({ name: 'rejection_reason', type: 'text', nullable: true })
  rejectionReason: string;

  @Column({ name: 'initiated_by', type: 'enum', enum: RefundInitiator })
  initiatedBy: RefundInitiator;

  @Column({ name: 'processed_by', nullable: true })
  processedBy: number;

  @Column({ name: 'requested_at', type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  requestedAt: Date;

  @Column({ name: 'processed_at', type: 'timestamp', nullable: true })
  processedAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
