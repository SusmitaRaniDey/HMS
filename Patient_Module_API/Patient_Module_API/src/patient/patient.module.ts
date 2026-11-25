import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppointmentsModule } from 'src/appointments/appointments.module';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { BillingModule } from 'src/billing/billing.module';
import { InvoicePdfService } from 'src/common/invoice-pdf.service';
import { SslcommerzVerificationService } from 'src/common/payments/sslcommerz-verification.service';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { PatientAuthGuard } from './guards/patient-auth.guard';
import { PatientController } from './patient.controller';
import { PatientService } from './patient.service';
import { EmergencyConsultationModule } from 'src/emergency-consultation/emergency-consultation.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Patients,
      Appointment,
      DiagnosticBooking,
      Diagnostic,
      Doctor,
    ]),
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        secret: config.get('ACCESS_TOKEN_SEC'),
        signOptions: { expiresIn: '24h' },
      }),
      inject: [ConfigService],
    }),
    AppointmentsModule,
    EmergencyConsultationModule,
    BillingModule,
  ],
  providers: [
    PatientService,
    PatientAuthGuard,
    SslcommerzVerificationService,
    InvoicePdfService,
  ],
  controllers: [PatientController],
  exports: [PatientService],
})
export class PatientModule {}
