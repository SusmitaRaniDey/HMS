import { describe, expect, it, jest } from '@jest/globals';
import { DoctorService } from './doctor.service';

describe('DoctorService startup safety', () => {
  it('does not read or write doctor records during module initialization', async () => {
    const doctorRepo = {
      find: jest.fn(),
      save: jest.fn(),
      update: jest.fn(),
    };
    const service = new DoctorService(
      doctorRepo as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await service.onModuleInit();

    expect(doctorRepo.find).not.toHaveBeenCalled();
    expect(doctorRepo.save).not.toHaveBeenCalled();
    expect(doctorRepo.update).not.toHaveBeenCalled();
  });
});
