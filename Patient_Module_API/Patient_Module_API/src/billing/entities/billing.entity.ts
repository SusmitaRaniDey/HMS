import { Appointment } from 'src/appointments/entities/appointments.entity';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * Bill types are intentionally a plain string (not a DB enum) so new
 * billing sources can be added later without a migration. These are the
 * values the automatic hooks currently assign; `BillingService.create`
 * (the manual/admin path) can accept any string.
 */
export const BillType = {
  APPOINTMENT: 'appointment',
  ONLINE_CONSULTATION: 'online_consultation',
  EMERGENCY_CONSULTATION: 'emergency_consultation',
  DIAGNOSTIC_BOOKING: 'diagnostic_booking',
  OTHER: 'other',
} as const;
export type BillTypeValue = (typeof BillType)[keyof typeof BillType];

@Entity('billing')
export class Billing {
  @PrimaryGeneratedColumn()
  id: number;

  // Backfilled right after insert as `INV-` + zero-padded id, so it is
  // race-free without a separate counter table. Nullable only for the
  // brief window between insert and that follow-up update.
  @Column({
    name: 'invoice_number',
    type: 'varchar',
    unique: true,
    nullable: true,
    length: 20,
  })
  invoiceNumber: string | null;

  @ManyToOne(() => Patients, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: Patients;

  @Column({ name: 'patient_id' })
  patientId: number;

  @ManyToOne(() => Appointment, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'appointment_id' })
  appointment: Appointment | null;

  @Column({ name: 'appointment_id', type: 'int', nullable: true, unique: true })
  appointmentId: number | null;

  @ManyToOne(() => DiagnosticBooking, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'diagnostic_booking_id' })
  diagnosticBooking: DiagnosticBooking | null;

  @Column({
    name: 'diagnostic_booking_id',
    type: 'int',
    nullable: true,
    unique: true,
  })
  diagnosticBookingId: number | null;

  @Column({ name: 'bill_type', length: 50 })
  billType: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  subtotal: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  discount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  tax: number;

  @Column({ name: 'total_amount', type: 'decimal', precision: 10, scale: 2 })
  totalAmount: number;

  @Column({ name: 'payment_method', length: 100 })
  paymentMethod: string;

  @Column({ name: 'payment_status', length: 50 })
  paymentStatus: string;

  @Column({
    name: 'transaction_id',
    type: 'varchar',
    nullable: true,
    length: 255,
  })
  transactionId: string | null;

  @Column({ length: 10, default: 'BDT' })
  currency: string;

  @Column({
    name: 'invoice_date',
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP',
  })
  invoiceDate: Date;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
