import { IsOptional, IsString } from 'class-validator';

export class ConfirmPaymentDto {
  @IsString()
  transactionId: string;

  // SSLCommerz's val_id from the SDK/redirect callback — required in
  // production, where it's re-checked against SSLCommerz's validator API.
  @IsString()
  @IsOptional()
  validationId?: string;

  @IsString()
  @IsOptional()
  bankTransactionId?: string;
}
