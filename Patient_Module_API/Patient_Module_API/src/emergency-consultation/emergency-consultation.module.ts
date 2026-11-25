import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { BillingModule } from 'src/billing/billing.module';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { ZoomModule } from 'src/zoom/zoom.module';
import { EmergencyAvailability } from './entities/emergency-availability.entity';
import { EmergencyConsultationService } from './emergency-consultation.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      EmergencyAvailability, Appointment, Doctor, Patients,
    ]),
    ZoomModule,
    BillingModule,
  ],
  providers: [EmergencyConsultationService],
  exports: [EmergencyConsultationService],
})
export class EmergencyConsultationModule {}
