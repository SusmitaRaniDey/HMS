import {
  IsArray,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class UpdateDoctorProfileDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsString()
  @IsOptional()
  degrees?: string;

  @IsString()
  @IsOptional()
  biography?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  languages?: string[];

  @IsString()
  @IsOptional()
  profilePic?: string;

  @IsObject()
  @IsOptional()
  slots?: Record<string, string>;

  @IsNumber()
  @IsOptional()
  @Min(0)
  available_slots?: number;
}
