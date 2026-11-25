import { Logger, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProfileImageUrlInterceptor } from './common/profile-image-url.interceptor';
import { AdminAuthModule } from './admin_auth/admin_auth.module';
import { AdminAuditLog } from './admin_auth/entities/admin-audit-log.entity';
import { Admin } from './admin_auth/entities/admin.entity';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AppointmentsModule } from './appointments/appointments.module';
import { Appointment } from './appointments/entities/appointments.entity';
import { BillingModule } from './billing/billing.module';
import { Billing } from './billing/entities/billing.entity';
import { DiagnosticBookingModule } from './diagnostic-booking/diagnostic-booking.module';
import { DiagnosticBooking } from './diagnostic-booking/entities/diagnostic-booking.entity';
import { DiagnosticsModule } from './diagnostics/diagnostics.module';
import { Diagnostic } from './diagnostics/entities/diagnostics.entity';
import { DoctorModule } from './doctor/doctor.module';
import { Doctor } from './doctor/entities/doctor.entity';
import { MedicineData } from './medicine-data/entities/medicine-data.entity';
import { MedicineDataModule } from './medicine-data/medicine-data.module';
import { Patients } from './patient/entities/patient.entity';
import { PatientModule } from './patient/patient.module';
import { PrescriptionModule } from './prescriptions/prescription.module';
import { Prescription } from './prescriptions/entities/prescription.entity';
import { ZoomModule } from './zoom/zoom.module';
import { EmergencyConsultationModule } from './emergency-consultation/emergency-consultation.module';
import { EmergencyAvailability } from './emergency-consultation/entities/emergency-availability.entity';

export function isSchemaSynchronizationAllowed(
  requested: boolean,
  nodeEnv: string,
): boolean {
  return requested && nodeEnv === 'test';
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    // Global default rate limit for every route (60 req/min per IP).
    // Login endpoints additionally apply a much stricter override via
    // @Throttle(...) to slow down credential-stuffing/brute-force attempts.
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60_000,
        limit: 60,
      },
    ]),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const requestedSynchronize =
          config.get<string>('DB_SYNCHRONIZE')?.toLowerCase() === 'true';
        const nodeEnv = config.get<string>('NODE_ENV') || 'development';
        // Schema synchronization may alter/rebuild MySQL columns at every
        // bootstrap. Restrict it to isolated test databases; persisted
        // development and production databases must use migrations.
        const synchronize = isSchemaSynchronizationAllowed(
          requestedSynchronize,
          nodeEnv,
        );
        if (requestedSynchronize && !synchronize) {
          new Logger('Database').warn(
            'DB_SYNCHRONIZE=true was ignored to protect persisted data. Use a migration for schema changes.',
          );
        }

        return {
          type: 'mysql',
          host: config.get('DB_HOST'),
          port: config.get<number>('DB_PORT'),
          username: config.get('DB_USER'),
          password: config.get('DB_PASS'),
          database: config.get('DB_NAME'),
          autoLoadEntities: true,
          entities: [
            Patients,
            Admin,
            AdminAuditLog,
            Doctor,
            Diagnostic,
            Appointment,
            DiagnosticBooking,
            Prescription,
            MedicineData,
            EmergencyAvailability,
            Billing,
          ],
          synchronize,
        };
      },
    }),
    AdminAuthModule,
    DoctorModule,
    PatientModule,
    DiagnosticsModule,
    AppointmentsModule,
    DiagnosticBookingModule,
    PrescriptionModule,
    MedicineDataModule,
    ZoomModule,
    EmergencyConsultationModule,
    BillingModule,
  ],
  controllers: [AppController],
  providers: [
    ProfileImageUrlInterceptor,
    AppService,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
