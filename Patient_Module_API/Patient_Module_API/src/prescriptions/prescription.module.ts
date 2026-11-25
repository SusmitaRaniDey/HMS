import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Prescription } from './entities/prescription.entity';
import { PrescriptionService } from './prescription.service';
import { PrescriptionController } from './prescription.controller';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Appointment } from 'src/appointments/entities/appointments.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Prescription, Doctor, Patients, Appointment]),
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('ACCESS_TOKEN_SEC'),
      }),
    }),
  ],
  controllers: [PrescriptionController],
  providers: [PrescriptionService],
  exports: [PrescriptionService],
})
export class PrescriptionModule {}
