import { IsDateString, IsInt, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class CancelAppointmentDto {
  @IsString()
  cancellationReason: string;
}

export class ReassignAppointmentDto {
  @IsInt()
  newDoctorId: number;
}

export class RescheduleAppointmentDto {
  @IsInt()
  doctorId: number;

  @IsDateString()
  date: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/)
  timeSlot: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
