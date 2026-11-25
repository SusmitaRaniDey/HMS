import { Type } from 'class-transformer';
import {
  IsArray,
  IsEmail,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

export class DayScheduleDto {
  @IsString()
  day!: string; // e.g., 'Monday', 'Tuesday', 'Sunday'

  @IsString()
  startTime!: string; // e.g., '09:00'

  @IsString()
  endTime: string; // e.g., '17:00'
}

export class OnlineScheduleDto {
  @IsString()
  day!: string; // e.g., 'Monday', 'Tuesday', 'Sunday'

  @IsString()
  startTime!: string; // e.g., '09:00'

  @IsString()
  endTime: string; // e.g., '17:00'
}

export class UpdateDoctorDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsString()
  @IsOptional()
  degrees?: string;

  @IsString()
  @IsOptional()
  specialty?: string;

  @IsNumber()
  @IsOptional()
  @Min(0)
  experience?: number;

  @IsString()
  @IsOptional()
  working_at?: string;

  @IsNumber()
  @IsOptional()
  @Min(0)
  fee?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  onlineFee?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  offlineFee?: number;

  @IsString()
  @IsOptional()
  profilePic?: string;

  @IsString()
  @IsOptional()
  biography?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  languages?: string[];

  // @IsObject()
  // @IsOptional()
  // slots?: Record<string, string>;

  @IsNumber()
  @IsOptional()
  @Min(0)
  available_slots?: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DayScheduleDto)
  @IsOptional()
  workingDays?: DayScheduleDto[]; // Days the doctor works with start/end times

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OnlineScheduleDto)
  @IsOptional()
  onlineSchedule?: OnlineScheduleDto[]; // Online days with start/end times

  @IsNumber()
  @IsOptional()
  @Min(30)
  consultLimitPerDay?: number; // Max patients per day (default 30)
}
