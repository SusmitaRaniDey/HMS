import { IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateAppointmentDto {
  @IsNumber()
  doctorId: number;

  @IsNumber()
  patientId: number;

  @IsString()
  date: string; // YYYY-MM-DD

  @IsNumber()
  @IsOptional()
  serialNumber?: number;

  @IsEnum(['online', 'offline'])
  @IsOptional()
  type?: string;

  @IsEnum(['pending', 'confirmed', 'cancelled', 'completed'])
  @IsOptional()
  status?: string;

  @IsString()
  @IsOptional()
  startTime?: string; // ISO datetime for online meetings

  @IsString()
  @IsOptional()
  timeSlot?: string; // "HH:MM" — the specific 5-minute slot selected by the patient

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
