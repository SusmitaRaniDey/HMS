import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { BillType } from '../entities/billing.entity';

/**
 * Manual/admin creation path for billing types that don't originate from
 * an appointment or diagnostic booking (e.g. a future medicine-purchase
 * bill). Automatic invoices from successful payments never go through
 * this DTO — see BillingService.createFromAppointment/createFromDiagnosticBooking.
 */
export class CreateBillingDto {
  @Type(() => Number)
  @IsInt()
  patientId: number;

  @IsIn(Object.values(BillType))
  billType: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  totalAmount: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  discount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  tax?: number;

  @IsString()
  paymentMethod: string;

  @IsOptional()
  @IsString()
  paymentStatus?: string;

  @IsOptional()
  @IsString()
  transactionId?: string;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  description?: string;
}
