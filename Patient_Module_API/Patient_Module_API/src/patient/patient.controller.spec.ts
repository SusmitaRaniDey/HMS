import { Test, TestingModule } from '@nestjs/testing';
import { PatientController } from './patient.controller';
import { PatientService } from './patient.service';

describe('PatientController', () => {
  let controller: PatientController;

  const mockPatientService = {
    registerWithEmail: jest.fn(),
    registerWithPhone: jest.fn(),
    loginPatient: jest.fn(),
    getPatientProfile: jest.fn(),
    updatePatientProfile: jest.fn(),
    updatePassword: jest.fn(),
    bookAppointment: jest.fn(),
    getPatientAppointments: jest.fn(),
    getUpcomingAppointments: jest.fn(),
    getAppointmentHistory: jest.fn(),
    cancelAppointment: jest.fn(),
    getAllDiagnostics: jest.fn(),
    bookDiagnostic: jest.fn(),
    getPatientBookings: jest.fn(),
    getUpcomingBookings: jest.fn(),
    getBookingHistory: jest.fn(),
    cancelBooking: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PatientController],
      providers: [
        {
          provide: PatientService,
          useValue: mockPatientService,
        },
      ],
    }).compile();

    controller = module.get<PatientController>(PatientController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('auth endpoints', () => {
    it('should call registerWithEmail', async () => {
      const dto = { name: 'John', email: 'john@test.com', password: 'pass123' };
      mockPatientService.registerWithEmail.mockResolvedValue({ id: 1, ...dto });

      await controller.registerWithEmail(dto);
      expect(mockPatientService.registerWithEmail).toHaveBeenCalledWith(dto);
    });

    it('should call loginPatient', async () => {
      const dto = { email: 'john@test.com', password: 'pass123' };
      mockPatientService.loginPatient.mockResolvedValue({
        accessToken: 'token123',
      });

      await controller.loginPatient(dto);
      expect(mockPatientService.loginPatient).toHaveBeenCalledWith(dto);
    });
  });
});
