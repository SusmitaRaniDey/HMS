import {
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
} from 'class-validator';

export class BookDiagnosticDto {
  @IsNumber()
  @IsNotEmpty()
  diagnosticId!: number;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  scheduleDate!: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  paymentMethod?: string;

  @IsOptional()
  @IsString()
  paymentStatus?: string;

  @IsOptional()
  @IsString()
  isPaid?: string;

  @IsOptional()
  @IsString()
  transactionId?: string;

  @IsOptional()
  @IsString()
  bankTransactionId?: string;

  @IsOptional()
  @IsNumber()
  paidAmount?: number;

  @IsOptional()
  @IsNumber()
  prescriptionId?: number;

  @IsOptional()
  @IsBoolean()
  isPrescribed?: boolean;
}
