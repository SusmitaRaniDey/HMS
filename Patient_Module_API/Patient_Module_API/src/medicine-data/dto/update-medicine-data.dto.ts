import { PartialType } from '@nestjs/mapped-types';
import { CreateMedicineDataDto } from './create-medicine-data.dto';

export class UpdateMedicineDataDto extends PartialType(CreateMedicineDataDto) {}
