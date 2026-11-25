import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateMedicineDataDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  company: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  trade_name: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  generic_name_with_strength: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  dosage_form: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  dar_no: string;
}
