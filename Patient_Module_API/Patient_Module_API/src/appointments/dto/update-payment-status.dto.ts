import { IsNumber, IsOptional, IsString } from 'class-validator';

export class UpdatePaymentStatusDto {
  @IsString()
  isPaid: string;

  @IsString()
  @IsOptional()
  paymentMethod?: string;

  @IsString()
  @IsOptional()
  paymentStatus?: string;

  @IsString()
  @IsOptional()
  transactionId?: string;

  @IsString()
  @IsOptional()
  bankTransactionId?: string;

  @IsNumber()
  @IsOptional()
  paidAmount?: number;
}
