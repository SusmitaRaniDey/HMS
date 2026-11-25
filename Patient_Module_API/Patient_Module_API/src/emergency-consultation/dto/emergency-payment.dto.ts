import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class InitiateEmergencyPaymentDto {
  @IsNumber()
  doctorId: number;
}

export class CompleteEmergencyPaymentDto {
  @IsString()
  @IsNotEmpty()
  transactionId: string;

  @IsString()
  @IsOptional()
  validationId?: string;

  @IsString()
  @IsOptional()
  bankTransactionId?: string;

  @IsString()
  @IsOptional()
  paymentMethod?: string;
}

export class EmergencyPaymentCallbackDto {
  @IsString()
  @IsOptional()
  tran_id?: string;

  @IsString()
  @IsOptional()
  val_id?: string;

  @IsString()
  @IsOptional()
  bank_tran_id?: string;

  @IsString()
  @IsOptional()
  card_type?: string;
}
