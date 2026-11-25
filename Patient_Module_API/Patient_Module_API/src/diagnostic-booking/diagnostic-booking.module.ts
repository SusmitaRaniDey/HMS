import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Prescription } from 'src/prescriptions/entities/prescription.entity';
import { DiagnosticBookingController } from './diagnostic-booking.controller';
import { DiagnosticBookingService } from './diagnostic-booking.service';
import { DiagnosticBooking } from './entities/diagnostic-booking.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      DiagnosticBooking,
      Diagnostic,
      Patients,
      Prescription,
    ]),
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('ACCESS_TOKEN_SEC'),
      }),
    }),
  ],
  controllers: [DiagnosticBookingController],
  providers: [DiagnosticBookingService],
  exports: [DiagnosticBookingService],
})
export class DiagnosticBookingModule {}
