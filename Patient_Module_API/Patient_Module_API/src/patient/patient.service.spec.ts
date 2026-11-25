import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { DiagnosticBooking } from 'src/diagnostic-booking/entities/diagnostic-booking.entity';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { PatientService } from './patient.service';

describe('PatientService', () => {
  let service: PatientService;

  beforeEach(async () => {
    const mockUserRepo = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      findAndCount: jest.fn(),
      query: jest.fn(),
    };

    const mockAppointmentRepo = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      find: jest.fn(),
      findAndCount: jest.fn(),
    };

    const mockBookingRepo = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      find: jest.fn(),
      findAndCount: jest.fn(),
    };

    const mockDiagnosticRepo = {
      findOne: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const mockJwtService = {
      sign: jest.fn(),
      verify: jest.fn(),
    };

    const mockConfigService = {
      get: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PatientService,
        {
          provide: getRepositoryToken(Patients),

          useValue: mockUserRepo,
        },
        {
          provide: getRepositoryToken(Appointment),

          useValue: mockAppointmentRepo,
        },
        {
          provide: getRepositoryToken(DiagnosticBooking),

          useValue: mockBookingRepo,
        },
        {
          provide: getRepositoryToken(Diagnostic),

          useValue: mockDiagnosticRepo,
        },
        {
          provide: JwtService,

          useValue: mockJwtService,
        },
        {
          provide: ConfigService,

          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<PatientService>(PatientService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
