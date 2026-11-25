import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { InvoicePdfService } from 'src/common/invoice-pdf.service';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';
import { Billing } from './entities/billing.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Billing, Appointment, DiagnosticBooking, Patients]),
    // AdminAuthGuard (used via @UseGuards on BillingController) needs a
    // JwtService in scope — every other module that guards routes with it
    // (AppointmentsModule, PatientModule, ...) registers its own local
    // JwtModule for the same reason; the guard always passes an explicit
    // secret to `verify()` itself, so this registration's own secret is
    // never actually used.
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('ACCESS_TOKEN_SEC'),
      }),
    }),
  ],
  controllers: [BillingController],
  providers: [BillingService, InvoicePdfService],
  exports: [BillingService],
})
export class BillingModule {}
