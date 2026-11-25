import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Brackets, Repository } from 'typeorm';
import { CreateMedicineDataDto } from './dto/create-medicine-data.dto';
import { UpdateMedicineDataDto } from './dto/update-medicine-data.dto';
import { SearchMedicineDataDto } from './dto/search-medicine-data.dto';
import { MedicineData } from './entities/medicine-data.entity';

@Injectable()
export class MedicineDataService {
  constructor(
    @InjectRepository(MedicineData)
    private readonly medicineDataRepository: Repository<MedicineData>,
  ) {}

  async create(createMedicineDto: CreateMedicineDataDto): Promise<MedicineData> {
    const result = await this.medicineDataRepository
      .createQueryBuilder('medicine')
      .select('COALESCE(MAX(medicine.sl), 0)', 'maxSl')
      .getRawOne<{ maxSl: string | number }>();
    const medicine = this.medicineDataRepository.create({
      ...createMedicineDto,
      sl: Number(result?.maxSl ?? 0) + 1,
    });
    return this.medicineDataRepository.save(medicine);
  }

  async findAll(page = 1, limit = 20): Promise<{
    data: MedicineData[];
    total: number;
    page: number;
    limit: number;
  }> {
    const safePage = page > 0 ? page : 1;
    const safeLimit = [10, 25, 50, 100].includes(limit) ? limit : 10;

    const [data, total] = await this.medicineDataRepository.findAndCount({
      skip: (safePage - 1) * safeLimit,
      take: safeLimit,
      order: { sl: 'ASC' },
    });

    return {
      data,
      total,
      page: safePage,
      limit: safeLimit,
    };
  }

  async findOne(sl: number): Promise<MedicineData> {
    const medicine = await this.medicineDataRepository.findOne({ where: { sl } });

    if (!medicine) {
      throw new NotFoundException(`Medicine with sl ${sl} not found`);
    }

    return medicine;
  }

  async update(
    sl: number,
    updateMedicineDto: UpdateMedicineDataDto,
  ): Promise<MedicineData> {
    const existingMedicine = await this.findOne(sl);

    await this.medicineDataRepository.update(existingMedicine.sl, updateMedicineDto);

    return this.findOne(sl);
  }

  async remove(sl: number): Promise<void> {
    const result = await this.medicineDataRepository.delete(sl);

    if (result.affected === 0) {
      throw new NotFoundException(`Medicine with sl ${sl} not found`);
    }
  }

  async suggestions(query: string, limit = 12): Promise<MedicineData[]> {
    const term = query?.trim();
    if (!term) return [];

    return this.medicineDataRepository
      .createQueryBuilder('medicine')
      .select([
        'medicine.sl',
        'medicine.company',
        'medicine.trade_name',
        'medicine.generic_name_with_strength',
        'medicine.dosage_form',
        'medicine.dar_no',
      ])
      .where('medicine.trade_name LIKE :prefix', { prefix: `${term}%` })
      .orderBy('medicine.trade_name', 'ASC')
      .take(Math.min(Math.max(limit, 1), 20))
      .getMany();
  }

  async search(query: SearchMedicineDataDto): Promise<{
    data: MedicineData[];
    total: number;
    page: number;
    limit: number;
  }> {
    const page = Math.max(query.page || 1, 1);
    const limit = [10, 25, 50, 100].includes(query.limit) ? query.limit : 10;
    const builder = this.medicineDataRepository.createQueryBuilder('medicine');
    const broadSearch = query.q?.trim();

    if (broadSearch) {
      const value = `%${broadSearch}%`;
      builder.where(
        new Brackets((qb) => {
          qb.where('medicine.trade_name LIKE :value', { value })
            .orWhere('medicine.generic_name_with_strength LIKE :value', { value })
            .orWhere('medicine.company LIKE :value', { value })
            .orWhere('medicine.dar_no LIKE :value', { value });
        }),
      );
    } else {
      const terms = [
        ['medicine.trade_name', query.tradeName],
        ['medicine.generic_name_with_strength', query.genericName],
        ['medicine.company', query.company],
        ['medicine.dar_no', query.darNo],
      ] as const;
      terms.forEach(([column, rawValue], index) => {
        if (!rawValue?.trim()) return;
        const parameter = `term${index}`;
        const clause = `${column} LIKE :${parameter}`;
        const parameters = { [parameter]: `%${rawValue.trim()}%` };
        if (builder.expressionMap.wheres.length === 0) builder.where(clause, parameters);
        else builder.orWhere(clause, parameters);
      });
    }

    if (builder.expressionMap.wheres.length === 0) return this.findAll(page, limit);
    const [data, total] = await builder
      .orderBy('medicine.sl', 'ASC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();
    return { data, total, page, limit };
  }
}
