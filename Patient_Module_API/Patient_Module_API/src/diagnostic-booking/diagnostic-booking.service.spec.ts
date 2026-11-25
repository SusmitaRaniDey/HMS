import { Test, TestingModule } from '@nestjs/testing';
import { DiagnosticBookingService } from './diagnostic-booking.service';

describe('DiagnosticBookingService', () => {
  let service: DiagnosticBookingService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [DiagnosticBookingService],
    }).compile();

    service = module.get<DiagnosticBookingService>(DiagnosticBookingService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
