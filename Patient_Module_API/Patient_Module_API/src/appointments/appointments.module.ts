import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BillingModule } from 'src/billing/billing.module';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { AppointmentsController } from './appointments.controller';
import { AppointmentsService } from './appointments.service';
import { Appointment } from './entities/appointments.entity';
import { RefundRequest } from './entities/refund-request.entity';
import { AdminRefundController, RefundController } from './refund.controller';
import { RefundService } from './refund.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Appointment, Doctor, Patients, RefundRequest]),
    BillingModule,
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('ACCESS_TOKEN_SEC'),
      }),
    }),
  ],
  controllers: [AppointmentsController, RefundController, AdminRefundController],
  providers: [AppointmentsService, RefundService],
  exports: [AppointmentsService],
})
export class AppointmentsModule {}
