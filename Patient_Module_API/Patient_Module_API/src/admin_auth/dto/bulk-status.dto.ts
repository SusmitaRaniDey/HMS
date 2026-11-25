import { IsArray, IsEnum, IsInt } from 'class-validator';

export class BulkStatusDto {
  @IsArray()
  @IsInt({ each: true })
  ids: number[];

  @IsEnum(['pending', 'confirmed', 'cancelled', 'completed'])
  status: string;
}
