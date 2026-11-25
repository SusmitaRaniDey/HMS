import { IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';

export class RegisterPhoneDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @Matches(/^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$/)
  phone: string;

  @IsString()
  @MinLength(6)
  password: string;
}
