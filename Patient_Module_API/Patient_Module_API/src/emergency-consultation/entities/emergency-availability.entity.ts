import { Doctor } from 'src/doctor/entities/doctor.entity';
import {
  Column, CreateDateColumn, Entity, JoinColumn, ManyToOne,
  PrimaryGeneratedColumn, UpdateDateColumn,
} from 'typeorm';

@Entity('emergency_availability')
export class EmergencyAvailability {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  doctorId!: number;

  @ManyToOne(() => Doctor, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'doctorId' })
  doctor!: Doctor;

  @Column({ type: 'datetime' })
  availableFrom!: Date;

  @Column({ type: 'datetime' })
  availableUntil!: Date;

  @Column({ default: true })
  isEnabled!: boolean;

  @Column({ default: true })
  enabledByAdmin!: boolean;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  emergencyFee?: number;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
