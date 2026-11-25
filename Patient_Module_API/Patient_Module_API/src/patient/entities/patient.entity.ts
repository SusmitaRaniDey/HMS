import { Appointment } from 'src/appointments/entities/appointments.entity';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity()
export class Patients {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  phone: string;

  @Column({ nullable: true })
  age?: number;

  @Column({ nullable: true })
  email?: string;

  // Excluded from default SELECTs so it never round-trips in an API
  // response by accident; call `.addSelect('patient.password')` explicitly
  // wherever the hash is actually needed (login password comparison).
  @Column({ select: false })
  password: string;

  @CreateDateColumn()
  createdAt: Date;

  @OneToMany(() => Appointment, (appointment) => appointment.patient)
  appointments: Appointment[];

  @OneToMany(
    () => DiagnosticBooking,
    (diagnosticBooking) => diagnosticBooking.patient,
  )
  diagnosticBookings: DiagnosticBooking[];
}
