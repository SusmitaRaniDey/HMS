import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('admin_audit_logs')
export class AdminAuditLog {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  adminId: number;

  @Column()
  adminEmail: string;

  @Column()
  action: string; // e.g., 'CREATE_DIAGNOSTIC', 'UPDATE_APPOINTMENT'

  @Column()
  resource: string; // e.g., 'Diagnostic', 'Appointment'

  @Column({ nullable: true })
  resourceId?: number;

  @Column({ type: 'text', nullable: true })
  changes?: string; // JSON stringified changes

  @Column({ nullable: true })
  ipAddress?: string;

  @Column({ nullable: true })
  userAgent?: string;

  @Column({ nullable: true })
  status: string; // 'success', 'failed'

  @CreateDateColumn()
  timestamp: Date;
}
