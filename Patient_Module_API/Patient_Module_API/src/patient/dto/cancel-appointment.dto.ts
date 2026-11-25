import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class CancelAppointmentDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(5)
  reason: string;
}
