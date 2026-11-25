import { Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { BookAppointmentDto } from 'src/patient/dto/book-appointment.dto';
import { BookDiagnosticDto } from 'src/patient/dto/book-diagnostic.dto';

export class AdminNewPatientDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsInt()
  @Min(1)
  @Max(120)
  age: number;

  @IsString()
  @IsNotEmpty()
  contactNumber: string;
}

export class AdminBookAppointmentDto extends BookAppointmentDto {
  @IsInt()
  @IsOptional()
  patientId?: number;

  @ValidateNested()
  @Type(() => AdminNewPatientDto)
  @IsOptional()
  newPatient?: AdminNewPatientDto;
}

export class AdminBookDiagnosticDto extends BookDiagnosticDto {
  @IsInt()
  @IsOptional()
  patientId?: number;

  @ValidateNested()
  @Type(() => AdminNewPatientDto)
  @IsOptional()
  newPatient?: AdminNewPatientDto;
}
