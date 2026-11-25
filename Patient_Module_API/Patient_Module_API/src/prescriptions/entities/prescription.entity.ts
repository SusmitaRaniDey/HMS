import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('prescriptions')
export class Prescription {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  appointmentId: number;

  @ManyToOne(() => Doctor, { eager: true, nullable: false })
  @JoinColumn({ name: 'doctorId' })
  doctor: Doctor;

  @Column()
  doctorId: number;

  @ManyToOne(() => Patients, { eager: true, nullable: false })
  @JoinColumn({ name: 'patientId' })
  patient: Patients;

  @Column()
  patientId: number;

  @Column({ nullable: true })
  patientAge: string;

  @Column({ nullable: true })
  diagnosis: string;

  @Column({ type: 'json', nullable: true })
  medicines: Array<{
    name: string;
    dose: string;
    frequency: string;
    duration: string;
  }> = [];

  @Column({ type: 'json', nullable: true })
  testsSuggested: string[] = [];

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ nullable: true, length: 1000 })
  pdfUrl: string;

  @CreateDateColumn()
  createdAt: Date;
}
