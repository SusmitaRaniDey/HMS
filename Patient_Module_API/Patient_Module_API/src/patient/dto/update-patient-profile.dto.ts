import { IsEmail, IsOptional, IsString, Matches } from 'class-validator';

export class UpdatePatientProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @Matches(/^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$/)
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;
}
