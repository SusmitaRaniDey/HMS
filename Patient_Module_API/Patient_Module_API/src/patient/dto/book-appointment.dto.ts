import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
} from 'class-validator';

export class BookAppointmentDto {
  @IsNumber()
  @IsNotEmpty()
  doctorId: number;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date: string;

  @IsEnum(['online', 'offline'])
  @IsOptional()
  type?: string;

  @IsString()
  @IsOptional()
  startTime?: string;

  @IsString()
  @IsOptional()
  timeSlot?: string;

  @IsString()
  @IsOptional()
  isPaid?: string;

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

  @IsString()
  @IsOptional()
  appointmentFor?: string;

  @IsString()
  @IsOptional()
  otherPatientName?: string;

  @IsNumber()
  @IsOptional()
  otherPatientAge?: number;

  @IsString()
  @IsOptional()
  otherPatientGender?: string;

  @IsString()
  @IsOptional()
  otherPatientContact?: string;
}
