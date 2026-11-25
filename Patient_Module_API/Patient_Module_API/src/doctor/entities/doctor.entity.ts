import { Appointment } from 'src/appointments/entities/appointments.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

// Interface for day schedule configuration
export interface DaySchedule {
  day: string; // e.g., 'Monday', 'Tuesday', 'Sunday'
  startTime: string; // e.g., '09:00'
  endTime: string; // e.g., '17:00'
}

export interface OnlineSchedule {
  day: string; // e.g., 'Monday', 'Tuesday', 'Sunday'
  startTime: string; // e.g., '09:00'
  endTime: string; // e.g., '17:00'
}

@Entity()
export class Doctor {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  name!: string;

  @Column({ unique: true })
  email!: string;

  // Excluded from default SELECTs so it never round-trips in an API
  // response by accident; call `.addSelect('doctor.password')` explicitly
  // wherever the hash is actually needed (login password comparison).
  @Column({ select: false })
  password!: string;

  @Column({ nullable: true })
  phone?: string;

  @Column({ nullable: true })
  degrees?: string;

  @Column()
  specialty!: string;

  @Column({ nullable: true })
  experience?: number;

  @Column({ nullable: true })
  working_at?: string;

  @Column({ nullable: true })
  fee?: number;

  @Column({ nullable: true })
  onlineFee?: number;

  @Column({ nullable: true })
  offlineFee?: number;

  @Column({ nullable: true })
  profilePic?: string;

  @Column({ type: 'text', nullable: true })
  biography?: string;

  @Column({ type: 'simple-array', nullable: true })
  languages?: string[];

  @Column({ nullable: true })
  available_slots?: number;

  @Column({ type: 'json', nullable: true })
  workingDays?: DaySchedule[]; // Array of days the doctor works with start/end times

  @Column({ type: 'json', nullable: true })
  onlineSchedule?: OnlineSchedule[]; // Online days with start/end times

  @Column({ default: 30 })
  consultLimitPerDay!: number; // Max patients per day (30 or 40)

  @OneToMany(() => Appointment, (appointment) => appointment.doctor, {
    onDelete: 'CASCADE',
    eager: false,
  })
  appointments!: Appointment[];

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
