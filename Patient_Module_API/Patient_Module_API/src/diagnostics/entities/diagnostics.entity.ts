import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('diagnostic_data')
export class Diagnostic {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  item_code: string;

  @Column()
  category: string; // e.g. Blood Test, Imaging, MRI, CT-SCAN

  @Column()
  test_name: string;

  @Column({ nullable: true })
  parameter: string;

  @Column({ nullable: true })
  normal_range: string;

  @Column({ nullable: true })
  unit: string;

  @Column('int', { nullable: true })
  price: number;

  @Column('text', { nullable: true })
  notes: string;

  // Kept alongside the diagnostic_data columns (not part of the original DDL) —
  // requires `ALTER TABLE diagnostic_data ADD COLUMN is_active TINYINT(1) DEFAULT 1, ADD COLUMN image VARCHAR(255) NULL;`
  @Column({ default: true })
  is_active: boolean;

  @Column({ nullable: true })
  image: string;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;

  @OneToMany(() => DiagnosticBooking, (booking) => booking.diagnostic)
  bookings: DiagnosticBooking[];
}
