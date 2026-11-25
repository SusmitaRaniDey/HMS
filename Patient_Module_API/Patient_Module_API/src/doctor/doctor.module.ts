import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { DoctorController } from './doctor.controller';
import { DoctorService } from './doctor.service';
import { DoctorAuthGuard } from './guards/doctor-auth.guard';
import { EmergencyConsultationModule } from 'src/emergency-consultation/emergency-consultation.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Doctor, Appointment]),
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        secret:
          config.get('DOCTOR_ACCESS_TOKEN_SEC') ||
          config.get('ACCESS_TOKEN_SEC'),
        signOptions: { expiresIn: '12h' },
      }),
      inject: [ConfigService],
    }),
    EmergencyConsultationModule,
  ],
  providers: [DoctorService, DoctorAuthGuard],
  controllers: [DoctorController],
  exports: [DoctorService],
})
export class DoctorModule {}
