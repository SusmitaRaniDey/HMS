import { IsEmail, IsString, MinLength, IsOptional } from 'class-validator';

export class DoctorRegisterDto {
  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  phone: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  specialty: string;

  @IsString()
  degrees: string;

  @IsString()
  working_at: string;
}

export class DoctorLoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}

export class ChangePasswordDto {
  @IsString()
  oldPassword: string;

  @IsString()
  @MinLength(6)
  newPassword: string;
}

export class AppointmentActionDto {
  @IsString()
  @IsOptional()
  reason?: string; // For reject/cancel operations
}
