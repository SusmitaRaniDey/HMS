import {
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class MedicineItemDto {
  @IsString()
  name!: string;

  @IsString()
  dose!: string;

  @IsString()
  frequency!: string;

  @IsString()
  duration!: string;
}

export class CreatePrescriptionDto {
  @IsNumber()
  appointmentId: number;

  @IsNumber()
  doctorId: number;

  @IsNumber()
  patientId: number;

  @IsString()
  @IsOptional()
  patientAge?: string;

  @IsString()
  @IsOptional()
  diagnosis?: string;

  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => MedicineItemDto)
  medicines?: MedicineItemDto[];

  @IsArray()
  @IsOptional()
  @IsString({ each: true })
  testsSuggested?: string[];

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  patientFcmToken?: string;
}
