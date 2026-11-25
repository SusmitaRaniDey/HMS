import {
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateDiagnosticBookingDto {
  @IsNumber()
  @IsNotEmpty()
  diagnosticId: number;

  @IsNumber()
  @IsNotEmpty()
  patientId: number;

  @IsString()
  @IsNotEmpty()
  scheduleDate: string;

  @IsString()
  @IsOptional()
  status?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsNumber()
  @IsOptional()
  prescriptionId?: number; // digital prescription from the system

  @IsString()
  @IsOptional()
  prescriptionImageUrl?: string; // physical prescription image fallback

  @IsBoolean()
  @IsOptional()
  isPrescribed?: boolean;

  @IsString()
  @IsOptional()
  patientFcmToken?: string;
}
