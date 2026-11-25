import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminAuthGuard } from 'src/admin_auth/admin_authGuard';
import {
  CurrentAdmin,
  type AdminContext,
} from 'src/admin_auth/decorators/current_admin_decorator';
import {
  CurrentPatient,
  type PatientContext,
} from 'src/patient/decorators/current-patient.decorator';
import { PatientAuthGuard } from 'src/patient/guards/patient-auth.guard';
import {
  AdminInitiateRefundDto,
  CreateRefundRequestDto,
  ProcessRefundDto,
  RejectRefundDto,
  RefundFilterDto,
} from './dto/refund-request.dto';
import { RefundService } from './refund.service';

@Controller('refunds')
@UseGuards(PatientAuthGuard)
export class RefundController {
  constructor(private readonly refundService: RefundService) {}

  @Post()
  create(
    @CurrentPatient() patient: PatientContext,
    @Body() dto: CreateRefundRequestDto,
  ) {
    return this.refundService.createForPatient(patient.id, dto);
  }

  @Get('my')
  myRefunds(@CurrentPatient() patient: PatientContext) {
    return this.refundService.findMine(patient.id);
  }

  @Get('appointment/:appointmentId')
  appointmentRefund(
    @CurrentPatient() patient: PatientContext,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
  ) {
    return this.refundService.findByAppointmentForPatient(
      appointmentId,
      patient.id,
    );
  }
}

@Controller('admin/refunds')
@UseGuards(AdminAuthGuard)
export class AdminRefundController {
  constructor(private readonly refundService: RefundService) {}

  @Get()
  findAll(@Query() filter: RefundFilterDto) {
    return this.refundService.findAll(filter);
  }

  @Patch(':id/processing')
  markProcessing(
    @CurrentAdmin() admin: AdminContext,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.refundService.markProcessing(id, admin.id);
  }

  @Patch(':id/process')
  process(
    @CurrentAdmin() admin: AdminContext,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ProcessRefundDto,
  ) {
    return this.refundService.process(id, admin.id, dto);
  }

  @Patch(':id/reject')
  reject(
    @CurrentAdmin() admin: AdminContext,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: RejectRefundDto,
  ) {
    return this.refundService.reject(id, admin.id, dto);
  }

  @Post('initiate/:appointmentId')
  initiate(
    @CurrentAdmin() admin: AdminContext,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
    @Body() dto: AdminInitiateRefundDto,
  ) {
    return this.refundService.adminInitiate(appointmentId, admin.id, dto);
  }
}
