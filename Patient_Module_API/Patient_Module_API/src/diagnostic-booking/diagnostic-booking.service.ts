/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Diagnostic } from 'src/diagnostics/entities/diagnostics.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Prescription } from 'src/prescriptions/entities/prescription.entity';
import { Repository } from 'typeorm';
import { CreateDiagnosticBookingDto } from './dto/create-diagnostic-booking.dto';
import { UpdateDiagnosticBookingDto } from './dto/update-diagnostic-booking.dto';
import { DiagnosticBooking } from './entities/diagnostic-booking.entity';

@Injectable()
export class DiagnosticBookingService {
  constructor(
    @InjectRepository(DiagnosticBooking)
    private bookingRepo: Repository<DiagnosticBooking>,

    @InjectRepository(Diagnostic)
    private diagnosticRepo: Repository<Diagnostic>,

    @InjectRepository(Patients)
    private patientRepo: Repository<Patients>,

    @InjectRepository(Prescription)
    private prescriptionRepo: Repository<Prescription>,
  ) {}

  async create(dto: CreateDiagnosticBookingDto) {
    const diagnostic = await this.diagnosticRepo.findOne({
      where: { id: dto.diagnosticId },
    });
    if (!diagnostic) throw new NotFoundException('Diagnostic Test not found');

    const patient = await this.patientRepo.findOne({
      where: { id: dto.patientId },
    });
    if (!patient) throw new NotFoundException('Patient not found');

    // Auto-detect isPrescribed
    let isPrescribed = false;
    if (dto.prescriptionId) {
      const prescription = await this.prescriptionRepo.findOne({
        where: { id: dto.prescriptionId },
      });
      if (prescription?.testsSuggested?.length) {
        isPrescribed = prescription.testsSuggested.some(
          (t) =>
            t.toLowerCase().trim() ===
            diagnostic.test_name.toLowerCase().trim(),
        );
      }
    }

    const booking = new DiagnosticBooking();
    booking.diagnostic = diagnostic;
    booking.patient = patient;
    booking.scheduleDate = dto.scheduleDate;
    booking.status = dto.status ?? 'pending';
    booking.notes = dto.notes ?? '';
    booking.prescriptionId = dto.prescriptionId as any;
    booking.prescriptionImageUrl = dto.prescriptionImageUrl as any;
    booking.isPrescribed = isPrescribed;

    return this.bookingRepo.save(booking);
  }

  findAll() {
    return this.bookingRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findAllPaginated(query?: {
    page?: number;
    limit?: number;
    status?: string;
    patientId?: number;
    scheduleDate?: string;
  }) {
    const page = query?.page && query.page > 0 ? query.page : 1;
    const limit = query?.limit && query.limit > 0 ? query.limit : 20;
    const where: Record<string, any> = {};

    if (query?.status && query.status !== 'all') {
      where['status'] = query.status;
    }
    if (query?.patientId) {
      where['patient'] = { id: query.patientId };
    }
    if (query?.scheduleDate) {
      where['scheduleDate'] = query.scheduleDate;
    }

    const [data, total] = await this.bookingRepo.findAndCount({
      where: where as any,
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { data, total, page, limit };
  }

  findBookingsByUser(patientId: number) {
    return this.bookingRepo.find({
      where: { patient: { id: patientId } },
      order: { createdAt: 'DESC' },
    });
  }

  findOne(id: number) {
    return this.bookingRepo.findOne({ where: { id } });
  }

  async update(id: number, dto: UpdateDiagnosticBookingDto) {
    const booking = await this.bookingRepo.findOne({ where: { id } });
    if (!booking) throw new NotFoundException('Booking not found');
    Object.assign(booking, dto);
    return this.bookingRepo.save(booking);
  }

  async remove(id: number) {
    const booking = await this.bookingRepo.findOne({ where: { id } });
    if (!booking) throw new NotFoundException('Booking not found');
    return this.bookingRepo.remove(booking);
  }

  async cancelBooking(id: number, reason: string) {
    const booking = await this.bookingRepo.findOne({ where: { id } });
    if (!booking) throw new NotFoundException('Booking not found');
    booking.status = 'cancelled';
    booking.cancellationReason = reason;
    return this.bookingRepo.save(booking);
  }

  async approveBooking(
    id: number,
    adminId: number,
    patientFcmToken?: string,
  ) {
    const booking = await this.bookingRepo.findOne({ where: { id } });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.status !== 'pending')
      throw new BadRequestException('Only pending bookings can be approved');

    booking.status = 'approved';
    booking.approvedBy = adminId;
    const saved = await this.bookingRepo.save(booking);

    if (patientFcmToken) {
      const testName =
        (booking.diagnostic as any)?.test_name ?? 'diagnostic test';
      await this.sendPushNotification(
        patientFcmToken,
        'Booking Approved',
        `Your booking for ${testName} has been approved.`,
        'booking_approved',
      ).catch(() => {});
    }

    return saved;
  }

  async rejectBooking(
    id: number,
    adminId: number,
    reason?: string,
    patientFcmToken?: string,
  ) {
    const booking = await this.bookingRepo.findOne({ where: { id } });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.status !== 'pending')
      throw new BadRequestException('Only pending bookings can be rejected');

    booking.status = 'rejected';
    booking.approvedBy = adminId;
    booking.adminNote = reason ?? '';
    const saved = await this.bookingRepo.save(booking);

    if (patientFcmToken) {
      const testName =
        (booking.diagnostic as any)?.test_name ?? 'diagnostic test';
      await this.sendPushNotification(
        patientFcmToken,
        'Booking Rejected',
        `Your booking for ${testName} has been rejected.${reason ? ` Reason: ${reason}` : ''}`,
        'booking_rejected',
      ).catch(() => {});
    }

    return saved;
  }

  async bulkUpdateStatus(ids: number[], status: string) {
    const result = await this.bookingRepo.update(
      { id: ids as any },
      { status } as any,
    );
    return { updated: result.affected || 0 };
  }

  private async sendPushNotification(
    fcmToken: string,
    title: string,
    body: string,
    type: string,
  ): Promise<void> {
    const fcmServerKey = process.env.FCM_SERVER_KEY;
    if (!fcmServerKey) return;

    await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${fcmServerKey}`,
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: { title, body },
        data: { type },
      }),
    });
  }
}
