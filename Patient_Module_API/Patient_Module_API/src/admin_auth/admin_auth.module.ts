import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { DiagnosticBookingModule } from 'src/diagnostic-booking/diagnostic-booking.module';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Prescription } from 'src/prescriptions/entities/prescription.entity';
import { ZoomModule } from 'src/zoom/zoom.module';
import { PatientModule } from 'src/patient/patient.module';
import { AdminAuthController } from './admin_auth.controller';
import { AdminAuthService } from './admin_auth.service';
import { AdminAuthGuard } from './admin_authGuard';
import { AdminAuditLog } from './entities/admin-audit-log.entity';
import { Admin } from './entities/admin.entity';
import { AdminAuditLogService } from './services/admin-audit-log.service';
import { EmergencyConsultationModule } from 'src/emergency-consultation/emergency-consultation.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Admin,
      AdminAuditLog,
      Diagnostic,
      Doctor,
      DiagnosticBooking,
      Appointment,
      Patients,
      Prescription,
    ]),
    ConfigModule,
    ZoomModule,
    PatientModule,
    EmergencyConsultationModule,
    DiagnosticBookingModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        secret:
          config.get('ADMIN_ACCESS_TOKEN_SEC') ||
          config.get('ACCESS_TOKEN_SEC'),
        signOptions: { expiresIn: '12h' },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AdminAuthController],
  providers: [AdminAuthService, AdminAuthGuard, AdminAuditLogService],
  exports: [AdminAuditLogService],
})
export class AdminAuthModule {}
