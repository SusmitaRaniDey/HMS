import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Res,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import * as fs from 'fs';
import { AdminAuthGuard } from 'src/admin_auth/admin_authGuard';
import { AnyAuthGuard } from 'src/common/guards/any-auth.guard';
import { CurrentAuth, type AuthContext } from 'src/common/guards/current-auth.decorator';
import { DoctorAuthGuard } from 'src/doctor/guards/doctor-auth.guard';
import { GetDoctor } from 'src/doctor/get-doctor.decorator';
import { Prescription } from './entities/prescription.entity';
import { PrescriptionService } from './prescription.service';
import { CreatePrescriptionDto } from './dto/create-prescription.dto';

@Controller('prescriptions')
export class PrescriptionController {
  constructor(private readonly prescriptionService: PrescriptionService) {}

  private assertAccess(auth: AuthContext, prescription: Prescription) {
    if (auth.role === 'admin') return;
    if (auth.role === 'patient' && auth.id === prescription.patientId) return;
    if (auth.role === 'doctor' && auth.id === prescription.doctorId) return;
    throw new ForbiddenException(
      'You do not have access to this prescription',
    );
  }

  @Post()
  @UseGuards(DoctorAuthGuard)
  create(
    @GetDoctor() doctor: { id: number },
    @Body() dto: CreatePrescriptionDto,
  ) {
    if (dto.doctorId !== doctor.id) {
      throw new ForbiddenException(
        'You can only issue prescriptions under your own doctor account',
      );
    }
    return this.prescriptionService.create(dto);
  }

  @Get()
  @UseGuards(AdminAuthGuard)
  findAll() {
    return this.prescriptionService.findAll();
  }

  @Get('patient/:patientId')
  @UseGuards(AnyAuthGuard)
  findByPatient(
    @Param('patientId', ParseIntPipe) patientId: number,
    @CurrentAuth() auth: AuthContext,
  ) {
    if (auth.role === 'patient' && auth.id !== patientId) {
      throw new ForbiddenException('You can only view your own prescriptions');
    }
    if (auth.role === 'doctor') {
      throw new ForbiddenException(
        'Doctors can only view prescriptions for a specific appointment',
      );
    }
    return this.prescriptionService.findByPatient(patientId);
  }

  @Get('appointment/:appointmentId')
  @UseGuards(AnyAuthGuard)
  async findByAppointment(
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
    @CurrentAuth() auth: AuthContext,
  ) {
    const prescription =
      await this.prescriptionService.findByAppointment(appointmentId);
    this.assertAccess(auth, prescription);
    return prescription;
  }

  @Get(':id')
  @UseGuards(AnyAuthGuard)
  async findOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAuth() auth: AuthContext,
  ) {
    const prescription = await this.prescriptionService.findOne(id);
    this.assertAccess(auth, prescription);
    return prescription;
  }

  @Get(':id/download')
  @UseGuards(AnyAuthGuard)
  async downloadPdf(
    @Param('id', ParseIntPipe) id: number,
    @CurrentAuth() auth: AuthContext,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const prescription = await this.prescriptionService.findOne(id);
    this.assertAccess(auth, prescription);

    const filePath = await this.prescriptionService.getPdfPath(id);
    const fileStream = fs.createReadStream(filePath);
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="prescription_${id}.pdf"`,
    });
    return new StreamableFile(fileStream);
  }
}
