import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { EmergencyAvailability } from 'src/emergency-consultation/entities/emergency-availability.entity';
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
export class Appointment {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Doctor, (doctor) => doctor.appointments, { eager: true })
  @JoinColumn({ name: 'doctorId' })
  doctor: Doctor;

  @Column()
  doctorId: number;

  @ManyToOne(() => Patients, (patient) => patient.appointments, { eager: true })
  @JoinColumn({ name: 'patientId' })
  patient: Patients;

  @Column()
  patientId: number;

  @Column({ type: 'date' })
  date: string;

  @Column({ nullable: true })
  serialNumber: number;

  @Column({
    type: 'enum',
    enum: ['online', 'offline'],
    default: 'offline',
  })
  type: string;

  @Column({
    type: 'enum',
    enum: ['pending', 'confirmed', 'cancelled', 'completed'],
    default: 'pending',
  })
  status: string;

  @Column({ nullable: true })
  cancellationReason: string;

  // Zoom meeting fields
  @Column({ nullable: true })
  zoomMeetingId: string;

  @Column({ nullable: true, length: 1000 })
  zoomJoinUrl: string;

  @Column({ nullable: true, length: 1000 })
  zoomStartUrl: string;

  @Column({ nullable: true })
  zoomPassword: string;

  @Column({
    type: 'enum',
    enum: ['scheduled', 'started', 'ended'],
    nullable: true,
  })
  meetingStatus: string;

  @Column({ nullable: true })
  startTime!: string; // ISO datetime for Zoom meeting scheduling

  @Column({ nullable: true })
  timeSlot: string; // "HH:MM" — the specific 5-minute slot booked

  @Column({ default: false })
  isEmergency: boolean;

  @Column({ nullable: true })
  emergencyAvailabilityId: number;

  @ManyToOne(() => EmergencyAvailability, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'emergencyAvailabilityId' })
  emergencyAvailability: EmergencyAvailability;

  // Payment fields
  @Column({ default: 'unpaid' })
  isPaid: string;

  @Column({ nullable: true })
  paymentMethod: string;

  @Column({ nullable: true })
  paymentStatus: string;

  @Column({ nullable: true })
  transactionId: string;

  @Column({ nullable: true })
  bankTransactionId: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  paidAmount: number;

  // Prescription link
  @Column({ nullable: true })
  prescriptionId: number;

  // Appointment for another patient fields
  @Column({ nullable: true })
  appointmentFor: string;

  @Column({ nullable: true })
  otherPatientName: string;

  @Column({ nullable: true })
  otherPatientAge: number;

  @Column({ nullable: true })
  otherPatientGender: string;

  @Column({ nullable: true })
  otherPatientContact: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
