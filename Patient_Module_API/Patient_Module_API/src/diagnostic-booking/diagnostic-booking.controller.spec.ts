import { Test, TestingModule } from '@nestjs/testing';
import { DiagnosticBookingController } from './diagnostic-booking.controller';

describe('DiagnosticBookingController', () => {
  let controller: DiagnosticBookingController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DiagnosticBookingController],
    }).compile();

    controller = module.get<DiagnosticBookingController>(
      DiagnosticBookingController,
    );
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
