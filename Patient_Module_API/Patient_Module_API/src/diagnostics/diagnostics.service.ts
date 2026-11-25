/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Like, Repository } from 'typeorm';
import { CreateDiagnosticDto } from './dto/create-diagnostic.dto';
import { UpdateDiagnosticDto } from './dto/update-diagnostic.dto';
import { Diagnostic } from './entities/diagnostics.entity';

@Injectable()
export class DiagnosticsService {
  constructor(
    @InjectRepository(Diagnostic) private diagnosisRepo: Repository<Diagnostic>,
  ) {}

  createTest(dto: CreateDiagnosticDto) {
    const test = this.diagnosisRepo.create(dto);
    return this.diagnosisRepo.save(test);
  }

  async findAllTest(query?: {
    page?: number;
    limit?: number;
    search?: string;
    category?: string;
    includeInactive?: boolean;
  }) {
    const page = query?.page && query.page > 0 ? query.page : 1;
    const limit = query?.limit && query.limit > 0 ? query.limit : 20;
    const where: any = {};

    if (query?.search) {
      where.test_name = Like(`%${query.search}%`);
    }

    if (query?.category) {
      where.category = Like(`%${query.category}%`);
    }

    if (!query?.includeInactive) {
      where.is_active = true;
    }

    const [data, total] = await this.diagnosisRepo.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
    });

    return { data, total, page, limit };
  }

  findOneTest(id: number) {
    return this.diagnosisRepo.findOne({ where: { id } });
  }

  // Distinct active test names, alphabetically sorted — powers the doctor
  // app's autocomplete when suggesting diagnostic tests on a prescription.
  // A test panel like CBC has many diagnostic_data rows (one per parameter)
  // sharing the same test_name, so this collapses them to one entry.
  async getDistinctTestNames() {
    const rows = await this.diagnosisRepo
      .createQueryBuilder('diag')
      .select('DISTINCT diag.test_name', 'test_name')
      .where('diag.is_active = true')
      .orderBy('diag.test_name', 'ASC')
      .getRawMany<{ test_name: string }>();
    return rows.map((r) => r.test_name).filter(Boolean);
  }

  updateTest(id: number, dto: UpdateDiagnosticDto) {
    return this.diagnosisRepo.update(id, dto);
  }

  deleteTest(id: number) {
    // keep as hard delete for now (consider soft delete later)
    return this.diagnosisRepo.delete(id);
  }

  searchTestByName(name: string) {
    return this.diagnosisRepo.find({
      where: { test_name: Like(`%${name}%`) },
    });
  }

  searchTestByCategory(category: string) {
    return this.diagnosisRepo.find({
      where: { category: Like(`%${category}%`) },
    });
  }
}
