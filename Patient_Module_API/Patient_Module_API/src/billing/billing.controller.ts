import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AdminAuthGuard } from 'src/admin_auth/admin_authGuard';
import { HasPermission } from 'src/admin_auth/decorators/has-permission.decorator';
import { AdminPermission } from 'src/admin_auth/enums/admin-permission.enum';
import { BillingService } from './billing.service';
import { BillingFilterDto } from './dto/billing-filter.dto';
import { CreateBillingDto } from './dto/create-billing.dto';

@Controller('admin/billing')
@UseGuards(AdminAuthGuard)
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @Get()
  @HasPermission(AdminPermission.READ_BILLING)
  findAll(@Query() filter: BillingFilterDto) {
    return this.billingService.findAllPaginated(filter);
  }

  @Get('invoice/:invoiceNumber')
  @HasPermission(AdminPermission.READ_BILLING)
  findByInvoiceNumber(@Param('invoiceNumber') invoiceNumber: string) {
    return this.billingService.findByInvoiceNumber(invoiceNumber);
  }

  @Get('patient/:patientId')
  @HasPermission(AdminPermission.READ_BILLING)
  findByPatient(@Param('patientId', ParseIntPipe) patientId: number) {
    return this.billingService.findByPatient(patientId);
  }

  @Get(':id')
  @HasPermission(AdminPermission.READ_BILLING)
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.billingService.findOne(id);
  }

  @Get(':id/invoice.pdf')
  @HasPermission(AdminPermission.READ_BILLING)
  async invoicePdf(
    @Param('id', ParseIntPipe) id: number,
    @Res() response: Response,
  ) {
    const pdf = await this.billingService.generateInvoicePdf(id);
    response.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `inline; filename="invoice_${id}.pdf"`,
    });
    response.end(pdf);
  }

  @Post()
  @HasPermission(AdminPermission.MANAGE_BILLING)
  create(@Body() dto: CreateBillingDto) {
    return this.billingService.create(dto);
  }
}
