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
import { DiagnosticsService } from './diagnostics.service';
import { CreateDiagnosticDto } from './dto/create-diagnostic.dto';
import { UpdateDiagnosticDto } from './dto/update-diagnostic.dto';

/**
 * Admins manage the diagnostic-test catalog through their own guarded
 * `/admin-auth/diagnostics/*` routes. This controller only needs to stay
 * reachable for read-only catalog browsing (patients/doctors picking a
 * test), so write routes here are locked to admin as a safety net and
 * reads require any authenticated user rather than being fully public.
 */
@Controller('diagnostics')
export class DiagnosticsController {
  constructor(private readonly diagnosticService: DiagnosticsService) {}

  @Post('create')
  @UseGuards(AdminAuthGuard)
  createTest(@Body() dto: CreateDiagnosticDto) {
    return this.diagnosticService.createTest(dto);
  }

  @Get()
  @UseGuards(AnyAuthGuard)
  findAllTest(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('includeInactive', new DefaultValuePipe(false))
    includeInactive?: boolean,
  ) {
    return this.diagnosticService.findAllTest({
      page,
      limit,
      search,
      category,
      includeInactive,
    });
  }

  // Distinct, de-duplicated test names for autocomplete (e.g. the doctor
  // app's "Diagnostic Tests Suggested" field on a prescription). Declared
  // before ':id' so "names" isn't swallowed by the numeric id route.
  @Get('names')
  @UseGuards(AnyAuthGuard)
  getDistinctTestNames() {
    return this.diagnosticService.getDistinctTestNames();
  }

  @Get(':id')
  @UseGuards(AnyAuthGuard)
  findOneTest(@Param('id', ParseIntPipe) id: number) {
    return this.diagnosticService.findOneTest(id);
  }

  @Put(':id')
  @UseGuards(AdminAuthGuard)
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateDiagnosticDto,
  ) {
    return this.diagnosticService.updateTest(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminAuthGuard)
  deleteTest(@Param('id', ParseIntPipe) id: number) {
    return this.diagnosticService.deleteTest(id);
  }

  @Get('search/name/:name')
  @UseGuards(AnyAuthGuard)
  searchByName(@Param('name') name: string) {
    return this.diagnosticService.searchTestByName(name);
  }

  @Get('search/category/:category')
  @UseGuards(AnyAuthGuard)
  searchByCategory(@Param('category') category: string) {
    return this.diagnosticService.searchTestByCategory(category);
  }
}
