import { Admin } from 'src/admin_auth/entities/admin.entity';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Prescription } from 'src/prescriptions/entities/prescription.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity()
export class DiagnosticBooking {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Diagnostic, (diagnostic) => diagnostic.bookings, {
    eager: true,
    onDelete: 'CASCADE',
  })
  diagnostic: Diagnostic;

  @ManyToOne(() => Patients, (patient) => patient.diagnosticBookings, {
    eager: true,
    onDelete: 'CASCADE',
  })
  patient: Patients;

  @Column()
  scheduleDate: string;

  @Column({ default: 'pending' })
  status: string; // pending | approved | rejected | confirmed | cancelled

  @Column({ nullable: true })
  notes: string;

  // Prescription verification fields
  @ManyToOne(() => Prescription, { eager: false, nullable: true })
  @JoinColumn({ name: 'prescriptionId' })
  prescription: Prescription;

  @Column({ nullable: true })
  prescriptionId: number;

  @Column({ nullable: true, length: 1000 })
  prescriptionImageUrl: string; // fallback for physical prescription uploads

  @Column({ default: false })
  isPrescribed: boolean; // auto-detected on creation

  // Admin action fields
  @Column({ nullable: true })
  adminNote: string;

  @ManyToOne(() => Admin, { eager: false, nullable: true })
  @JoinColumn({ name: 'approvedBy' })
  approvedByAdmin: Admin;

  @Column({ nullable: true })
  approvedBy: number;

  // Legacy payment fields (kept for backwards compat)
  @Column({ nullable: true })
  paymentMethod: string;

  @Column({ nullable: true })
  paymentStatus: string;

  @Column({ nullable: true })
  isPaid: string;

  @Column({ nullable: true })
  transactionId: string;

  @Column({ nullable: true })
  bankTransactionId: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  paidAmount: number;

  @Column({ nullable: true })
  cancellationReason: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
