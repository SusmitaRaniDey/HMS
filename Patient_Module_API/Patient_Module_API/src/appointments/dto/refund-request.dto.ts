import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import {
  RefundReason,
  RefundStatus,
} from '../entities/refund-request.entity';

export class CreateRefundRequestDto {
  @IsNumber()
  @IsOptional()
  appointmentId: number;

  @IsNumber()
  @IsOptional()
  appointment_id?: number;

  @IsEnum(RefundReason)
  reason: RefundReason;

  @IsString()
  @IsOptional()
  patientNote?: string;

  @IsString()
  refundToAccount: string;

  @IsString()
  @IsOptional()
  refund_to_account?: string;
}

export class ProcessRefundDto {
  @IsNumber()
  @Min(0)
  @IsOptional()
  refundedAmount: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  refunded_amount?: number;

  @IsString()
  @IsOptional()
  refundTransactionId: string;

  @IsString()
  @IsOptional()
  refund_transaction_id?: string;
}

export class RejectRefundDto {
  @IsString()
  @IsOptional()
  rejectionReason: string;

  @IsString()
  @IsOptional()
  rejection_reason?: string;
}

export class AdminInitiateRefundDto {
  @IsEnum(RefundReason)
  reason: RefundReason;

  @IsString()
  @IsOptional()
  patientNote?: string;

  @IsString()
  refundToAccount: string;

  @IsString()
  @IsOptional()
  refund_to_account?: string;
}

export class RefundFilterDto {
  @IsEnum(RefundStatus)
  @IsOptional()
  status?: RefundStatus;
}
