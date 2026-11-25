import { Type } from 'class-transformer';
import {
  IsBoolean, IsDateString, IsInt, IsNumber, IsOptional, Min,
} from 'class-validator';

export class SetEmergencyAvailabilityDto {
  @IsDateString()
  availableFrom!: string;

  @IsDateString()
  availableUntil!: string;

  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  enabledByAdmin?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  emergencyFee?: number;
}

export class AdminSetEmergencyAvailabilityDto extends SetEmergencyAvailabilityDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  doctorId!: number;
}
