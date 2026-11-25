import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminAuthGuard } from 'src/admin_auth/admin_authGuard';
import { AnyAuthGuard } from 'src/common/guards/any-auth.guard';
import { CreateMedicineDataDto } from './dto/create-medicine-data.dto';
import { SearchMedicineDataDto } from './dto/search-medicine-data.dto';
import { UpdateMedicineDataDto } from './dto/update-medicine-data.dto';
import { MedicineDataService } from './medicine-data.service';

@Controller('medicine-data')
export class MedicineDataController {
  constructor(private readonly medicineDataService: MedicineDataService) {}

  @Post()
  @UseGuards(AdminAuthGuard)
  create(@Body() createMedicineDto: CreateMedicineDataDto) {
    return this.medicineDataService.create(createMedicineDto);
  }

  @Get()
  @UseGuards(AnyAuthGuard)
  findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    return this.medicineDataService.findAll(page, limit);
  }

  @Get('search')
  @UseGuards(AnyAuthGuard)
  search(@Query() query: SearchMedicineDataDto) {
    return this.medicineDataService.search(query);
  }

  @Get('suggestions')
  @UseGuards(AnyAuthGuard)
  suggestions(
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(12), ParseIntPipe) limit: number,
  ) {
    return this.medicineDataService.suggestions(query, limit);
  }

  @Get(':sl')
  @UseGuards(AnyAuthGuard)
  findOne(@Param('sl', ParseIntPipe) sl: number) {
    return this.medicineDataService.findOne(sl);
  }

  @Put(':sl')
  @UseGuards(AdminAuthGuard)
  update(
    @Param('sl', ParseIntPipe) sl: number,
    @Body() updateMedicineDto: UpdateMedicineDataDto,
  ) {
    return this.medicineDataService.update(sl, updateMedicineDto);
  }

  @Delete(':sl')
  @UseGuards(AdminAuthGuard)
  remove(@Param('sl', ParseIntPipe) sl: number) {
    return this.medicineDataService.remove(sl);
  }
}
