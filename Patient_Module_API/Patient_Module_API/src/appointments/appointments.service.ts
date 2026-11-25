/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { BillingService } from 'src/billing/billing.service';
import {
  DaySchedule,
  Doctor,
  OnlineSchedule,
} from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Repository } from 'typeorm';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateAppointmentDto } from './dto/update-appointment.dto';
import { Appointment } from './entities/appointments.entity';

@Injectable()
export class AppointmentsService {
  constructor(
    @InjectRepository(Appointment)
    private appointmentRepo: Repository<Appointment>,

    @InjectRepository(Doctor)
    private doctorRepo: Repository<Doctor>,

    @InjectRepository(Patients)
    private userRepo: Repository<Patients>,

    private billingService: BillingService,
  ) {}

  private hideMeetingUrls<T extends Appointment | null>(appointment: T): T {
    if (!appointment) return appointment;
    return {
      ...appointment,
      zoomJoinUrl: null,
      zoomStartUrl: null,
    } as T;
  }

  private hideMeetingUrlsList(appointments: Appointment[]) {
    return appointments.map((appointment) => this.hideMeetingUrls(appointment));
  }

  /**
   * Get the day of week from a date string (YYYY-MM-DD)
   */
  private getDayOfWeek(dateStr: string): string {
    const date = new Date(dateStr);
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[date.getUTCDay()];
  }

  /**
   * Check if the doctor works on the given date
   */
  private isDoctorWorkingOnDay(
    doctor: Doctor,
    date: string,
  ): DaySchedule | null {
    const dayOfWeek = this.getDayOfWeek(date);
    const workingDay = doctor.workingDays?.find(
      (day) => day.day.toLowerCase() === dayOfWeek.toLowerCase(),
    );
    return workingDay || null;
  }

  private isDoctorOnlineOnDate(
    doctor: Doctor,
    date: string,
  ): OnlineSchedule | null {
    const dayOfWeek = this.getDayOfWeek(date);
    const onlineSlot = doctor.onlineSchedule?.find(
      (slot) =>
        (slot.day || (slot as any).date || '').toLowerCase() ===
        dayOfWeek.toLowerCase(),
    );
    return onlineSlot || null;
  }

  private getScheduleSlotCount(schedule: DaySchedule | OnlineSchedule): number {
    const [startHour, startMinute] = schedule.startTime.split(':').map(Number);
    const [endHour, endMinute] = schedule.endTime.split(':').map(Number);
    const duration = endHour * 60 + endMinute - (startHour * 60 + startMinute);
    return Number.isFinite(duration) && duration > 0
      ? Math.floor(duration / 5)
      : 0;
  }

  private isValidScheduleSlot(
    schedule: DaySchedule | OnlineSchedule,
    timeSlot: string,
  ): boolean {
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(timeSlot)) return false;
    const [hour, minute] = timeSlot.split(':').map(Number);
    const [startHour, startMinute] = schedule.startTime.split(':').map(Number);
    const [endHour, endMinute] = schedule.endTime.split(':').map(Number);
    const requested = hour * 60 + minute;
    const start = startHour * 60 + startMinute;
    const end = endHour * 60 + endMinute;
    return (
      requested >= start &&
      requested + 5 <= end &&
      (requested - start) % 5 === 0
    );
  }

  /**
   * Get next working day for doctor after a given date
   */
  getNextWorkingDay(doctor: Doctor, fromDate: string): Promise<string> {
    const currentDate = new Date(fromDate);
    let daysChecked = 0;
    const maxDays = 60; // Check up to 60 days in future

    while (daysChecked < maxDays) {
      currentDate.setUTCDate(currentDate.getUTCDate() + 1);
      daysChecked++;

      const dateStr = currentDate.toISOString().split('T')[0];
      if (this.isDoctorWorkingOnDay(doctor, dateStr)) {
        return Promise.resolve(dateStr);
      }
    }

    return Promise.reject(
      new BadRequestException(
        'Could not find next available working day for doctor',
      ),
    );
  }

  /**
   * Get count of appointments for a doctor on a specific date
   * Counts all non-cancelled appointments to determine serial number (queue position)
   */
  private async getAppointmentCountForDay(
    doctorId: number,
    date: string,
  ): Promise<number> {
    const count = await this.appointmentRepo
      .createQueryBuilder('appointment')
      .where('appointment.doctorId = :doctorId', { doctorId })
      .andWhere('appointment.date = :date', { date })
      .andWhere('appointment.status IN (:...statuses)', {
        statuses: ['pending', 'confirmed'],
      })
      .getCount();
    return count;
  }

  async create(dto: CreateAppointmentDto) {
    // Validate doctor exists
    const doctor = await this.doctorRepo.findOne({
      where: { id: dto.doctorId },
    });
    if (!doctor) throw new BadRequestException('Invalid doctorId');

    // Set default consult limit if not set
    if (!doctor.consultLimitPerDay) {
      doctor.consultLimitPerDay = 30;
    }

    // Validate patient exists
    const patient = await this.userRepo.findOne({
      where: { id: dto.patientId },
    });
    if (!patient) throw new BadRequestException('Invalid patientId');

    const existingAppointment = await this.appointmentRepo
      .createQueryBuilder('appointment')
      .where('appointment.patientId = :patientId', {
        patientId: dto.patientId,
      })
      .andWhere('appointment.doctorId = :doctorId', {
        doctorId: dto.doctorId,
      })
      .andWhere('appointment.date = :date', { date: dto.date })
      .andWhere('appointment.status IN (:...statuses)', {
        statuses: ['pending', 'confirmed', 'completed'],
      })
      .getOne();

    if (existingAppointment) {
      throw new BadRequestException(
        'This patient already has an appointment with this doctor on the selected date.',
      );
    }

    const appointmentType = dto.type || 'offline';

    // Check if doctor has the requested schedule configured
    if (
      appointmentType === 'offline' &&
      (!doctor.workingDays || doctor.workingDays.length === 0)
    ) {
      throw new BadRequestException(
        'Doctor has no offline schedule configured. Please contact administrator.',
      );
    }

    if (
      appointmentType === 'online' &&
      (!doctor.onlineSchedule || doctor.onlineSchedule.length === 0)
    ) {
      throw new BadRequestException(
        'Doctor has no online schedule configured. Please contact administrator.',
      );
    }

    let selectedSchedule: DaySchedule | OnlineSchedule | null;
    if (appointmentType === 'online') {
      const onlineSlot = this.isDoctorOnlineOnDate(doctor, dto.date);
      selectedSchedule = onlineSlot;
      if (!onlineSlot) {
        throw new BadRequestException(
          `Doctor is not available online on ${this.getDayOfWeek(dto.date)}`,
        );
      }
    } else if (
      !(selectedSchedule = this.isDoctorWorkingOnDay(doctor, dto.date))
    ) {
      // Find next available working day
      const nextWorkingDay = await this.getNextWorkingDay(doctor, dto.date);
      throw new BadRequestException(
        `Doctor does not work on ${this.getDayOfWeek(dto.date)}. Next available day: ${nextWorkingDay}`,
      );
    }

    if (
      dto.timeSlot &&
      (!selectedSchedule || !this.isValidScheduleSlot(selectedSchedule, dto.timeSlot))
    ) {
      throw new BadRequestException(
        `Time slot ${dto.timeSlot} is outside the doctor's configured working hours.`,
      );
    }

    const correctFee =
      appointmentType === 'online'
        ? (doctor.onlineFee ?? doctor.fee)
        : (doctor.offlineFee ?? doctor.fee);
    const isAdminHospitalPayment =
      dto.status === 'confirmed' && dto.paymentMethod === 'pay_in_hospital';

    // The slot-availability check, the daily-consult-limit check, and the
    // insert all happen inside one SERIALIZABLE transaction so two
    // concurrent booking requests for the same doctor/date/slot can't both
    // pass their checks before either commits (the previous check-then-
    // insert with no transaction allowed exactly that race). This mirrors
    // the pattern already used in AdminAuthService.rescheduleAppointment.
    const savedAppointment = await this.appointmentRepo.manager.transaction(
      'SERIALIZABLE',
      async (manager) => {
        const appointmentRepo = manager.getRepository(Appointment);

        if (dto.timeSlot) {
          const slotTaken = await appointmentRepo
            .createQueryBuilder('appointment')
            .where('appointment.doctorId = :doctorId', {
              doctorId: dto.doctorId,
            })
            .andWhere('appointment.date = :date', { date: dto.date })
            .andWhere('appointment.timeSlot = :timeSlot', {
              timeSlot: dto.timeSlot,
            })
            .andWhere('appointment.type = :type', {
              type: dto.type || 'offline',
            })
            .andWhere('appointment.status IN (:...statuses)', {
              statuses: ['pending', 'confirmed'],
            })
            .getOne();

          if (slotTaken) {
            throw new BadRequestException(
              `Time slot ${dto.timeSlot} is already booked. Please select another time slot.`,
            );
          }
        }

        const appointmentCountForDay = await appointmentRepo
          .createQueryBuilder('appointment')
          .where('appointment.doctorId = :doctorId', { doctorId: dto.doctorId })
          .andWhere('appointment.date = :date', { date: dto.date })
          .andWhere('appointment.status IN (:...statuses)', {
            statuses: ['pending', 'confirmed'],
          })
          .getCount();

        if (appointmentCountForDay >= doctor.consultLimitPerDay) {
          // Find next available working day with available slots
          let nextAvailableDate = dto.date;
          let found = false;

          for (let i = 0; i < 60; i++) {
            const dateToCheck = new Date(nextAvailableDate);
            dateToCheck.setUTCDate(dateToCheck.getUTCDate() + 1);
            nextAvailableDate = dateToCheck.toISOString().split('T')[0];

            if (this.isDoctorWorkingOnDay(doctor, nextAvailableDate)) {
              const countForNextDay = await this.getAppointmentCountForDay(
                dto.doctorId,
                nextAvailableDate,
              );
              if (countForNextDay < doctor.consultLimitPerDay) {
                found = true;
                break;
              }
            }
          }

          if (!found) {
            throw new BadRequestException(
              `Doctor has reached daily consultation limit (${doctor.consultLimitPerDay}). No available slots in next 60 days.`,
            );
          }

          throw new BadRequestException(
            `Doctor has reached daily consultation limit (${doctor.consultLimitPerDay}) for ${this.getDayOfWeek(dto.date)}. Next available appointment on ${nextAvailableDate}`,
          );
        }

        const serialNumber = appointmentCountForDay + 1;

        const appointment = appointmentRepo.create({
          ...dto,
          // The doctor's configured fee is always authoritative — never
          // trust a client-supplied amount, for either payment path.
          paidAmount: correctFee,
          // For an admin-confirmed hospital payment, money already changed
          // hands at the counter, so that path is trusted as-is. Every
          // other booking (i.e. an online SSLCommerz payment reported by
          // the patient's own client) starts unpaid/pending regardless of
          // what the client sent — it can only become "paid" through the
          // server-side verification in
          // AppointmentsService.confirmOnlinePayment, which re-checks the
          // transaction with SSLCommerz directly.
          ...(isAdminHospitalPayment
            ? {}
            : { isPaid: 'unpaid', paymentStatus: 'pending' }),
          serialNumber,
        });
        return appointmentRepo.save(appointment);
      },
    );

    // Money already changed hands at the counter for this path, so the
    // billing record is created once the transaction has actually
    // committed (never from inside it — the billing insert uses a
    // separate connection and would otherwise race the FK against an
    // uncommitted appointment row).
    if (isAdminHospitalPayment) {
      await this.billingService.createFromAppointment(savedAppointment);
    }

    return savedAppointment;
  }

  /**
   * Server-side confirmation for an online (SSLCommerz) appointment
   * payment. The client only ever gets to report a transactionId and the
   * gateway's validationId — never a "paid" flag directly — and this method
   * independently re-verifies that transaction with SSLCommerz before
   * marking anything as paid.
   */
  async confirmOnlinePayment(
    appointmentId: number,
    patientId: number,
    data: {
      transactionId: string;
      validationId?: string;
      bankTransactionId?: string;
    },
    verifier: {
      verify: (
        validationId: string | undefined,
        transactionId: string,
        expectedAmount: number,
      ) => Promise<void>;
    },
  ) {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId, patientId },
    });
    if (!appointment) throw new BadRequestException('Appointment not found');
    if (appointment.paymentStatus === 'completed') {
      return this.findOne(appointmentId);
    }

    await verifier.verify(
      data.validationId,
      data.transactionId,
      Number(appointment.paidAmount),
    );

    await this.appointmentRepo.update(appointmentId, {
      isPaid: 'paid',
      paymentStatus: 'completed',
      paymentMethod: 'sslcommerz',
      transactionId: data.transactionId,
      bankTransactionId: data.bankTransactionId,
    } as any);

    const confirmed = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
    });
    if (confirmed) {
      await this.billingService.createFromAppointment(confirmed);
    }

    return this.findOne(appointmentId);
  }

  async findAll() {
    console.log('🔍 findAll() called - no pagination');
    const appointments = await this.appointmentRepo.find({
      order: { date: 'ASC' },
    });
    return this.hideMeetingUrlsList(appointments);
  }

  async findAllPaginated(query?: {
    page?: number;
    limit?: number;
    status?: string;
    doctorId?: number;
    patientId?: number;
    date?: string;
  }) {
    console.log('📄 findAllPaginated() called with query:', query);
    const page = query?.page && query.page > 0 ? query.page : 1;
    const limit = query?.limit && query.limit > 0 ? query.limit : 20;
    const where: Record<string, any> = {};

    if (query?.status) {
      where['status'] = query.status;
    }

    if (query?.doctorId) {
      where['doctorId'] = query.doctorId;
    }

    if (query?.patientId) {
      where['patientId'] = query.patientId;
    }

    if (query?.date) {
      where['date'] = query.date;
    }

    const [data, total] = await this.appointmentRepo.findAndCount({
      where: where as any,
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { data: this.hideMeetingUrlsList(data), total, page, limit };
  }

  async findByDoctor(doctorId: number) {
    const appointments = await this.appointmentRepo.find({
      where: { doctorId },
      order: { date: 'ASC' },
    });
    return this.hideMeetingUrlsList(appointments);
  }

  async findByPatient(patientId: number) {
    const appointments = await this.appointmentRepo.find({
      where: { patientId },
      order: { date: 'DESC' },
    });
    return this.hideMeetingUrlsList(appointments);
  }

  async findOne(id: number) {
    const appointment = await this.appointmentRepo.findOne({ where: { id } });
    return this.hideMeetingUrls(appointment);
  }

  update(id: number, dto: UpdateAppointmentDto) {
    return this.appointmentRepo.update(id, dto);
  }

  remove(id: number) {
    return this.appointmentRepo.delete(id);
  }

  async cancelAppointment(id: number, reason: string) {
    const appt = await this.appointmentRepo.findOne({ where: { id } });
    if (!appt) throw new BadRequestException('Appointment not found');
    if (['cancelled', 'completed'].includes(appt.status)) {
      throw new BadRequestException(
        `A ${appt.status} appointment cannot be cancelled`,
      );
    }
    await this.appointmentRepo.update(id, {
      status: 'cancelled',
      cancellationReason: reason,
    } as any);
    return this.findOne(id);
  }

  async updatePaymentStatus(
    id: number,
    data: {
      isPaid: string;
      paymentMethod?: string;
      paymentStatus?: string;
      transactionId?: string;
      bankTransactionId?: string;
      paidAmount?: number;
    },
  ) {
    const appt = await this.appointmentRepo.findOne({ where: { id } });
    if (!appt) throw new BadRequestException('Appointment not found');
    await this.appointmentRepo.update(id, data as any);
    return this.findOne(id);
  }

  async bulkUpdateStatus(ids: number[], status: string) {
    const result = await this.appointmentRepo.update({ id: ids as any }, {
      status,
    } as any);
    return { updated: result.affected || 0 };
  }

  async reassignAppointment(id: number, newDoctorId: number) {
    const doctor = await this.doctorRepo.findOne({
      where: { id: newDoctorId },
    });
    if (!doctor) throw new BadRequestException('Doctor not found');

    await this.appointmentRepo.update(id, { doctorId: newDoctorId });
    return this.findOne(id);
  }

  /**
   * Get available working days for a doctor
   */
  async getDoctorWorkingDays(doctorId: number) {
    const doctor = await this.doctorRepo.findOne({
      where: { id: doctorId },
    });
    if (!doctor) throw new BadRequestException('Doctor not found');

    return {
      doctorId: doctor.id,
      name: doctor.name,
      workingDays: doctor.workingDays || [],
      onlineSchedule: doctor.onlineSchedule || [],
      consultLimitPerDay: doctor.consultLimitPerDay || 30,
    };
  }

  /**
   * Returns the list of booked time slots ("HH:MM") for a doctor on a specific date.
   * Used by all patients to see which slots are already taken.
   */
  async getBookedTimes(
    doctorId: number,
    date: string,
    type = 'offline',
  ): Promise<string[]> {
    const appointments = await this.appointmentRepo
      .createQueryBuilder('appointment')
      .where('appointment.doctorId = :doctorId', { doctorId })
      .andWhere('appointment.date = :date', { date })
      .andWhere('appointment.type = :type', { type })
      .andWhere('appointment.status IN (:...statuses)', {
        statuses: ['pending', 'confirmed'],
      })
      .andWhere('appointment.timeSlot IS NOT NULL')
      .select(['appointment.timeSlot'])
      .getMany();

    return appointments
      .map((a) => a.timeSlot)
      .filter((t): t is string => t != null);
  }

  /**
   * Returns the full time-slot grid for a doctor on a specific date,
   * with each slot marked as booked or available.
   */
  async getTimeSlots(doctorId: number, date: string, type = 'offline') {
    const doctor = await this.doctorRepo.findOne({ where: { id: doctorId } });
    if (!doctor) throw new BadRequestException('Doctor not found');

    const schedule =
      type === 'online'
        ? this.isDoctorOnlineOnDate(doctor, date)
        : this.isDoctorWorkingOnDay(doctor, date);

    if (!schedule) return [];

    const bookedTimes = await this.getBookedTimes(doctorId, date, type);
    const bookedSet = new Set(bookedTimes);

    const startParts = schedule.startTime.split(':').map(Number);
    const endParts = schedule.endTime.split(':').map(Number);
    const startMinutes = startParts[0] * 60 + startParts[1];
    const endMinutes = endParts[0] * 60 + endParts[1];

    const slots: {
      slotId: number;
      date: string;
      startTime: string;
      endTime: string;
      isBooked: boolean;
    }[] = [];

    let cur = startMinutes;
    let idx = 0;

    const pad = (n: number) => String(n).padStart(2, '0');

    while (cur + 5 <= endMinutes) {
      const slotStart = `${pad(Math.floor(cur / 60))}:${pad(cur % 60)}`;
      const slotEnd = `${pad(Math.floor((cur + 5) / 60))}:${pad((cur + 5) % 60)}`;

      slots.push({
        slotId: idx,
        date,
        startTime: slotStart,
        endTime: slotEnd,
        isBooked: bookedSet.has(slotStart),
      });

      cur += 5;
      idx++;
    }

    return slots;
  }

  /**
   * Get available appointment slots for a doctor on a specific date
   */
  async getAvailableSlots(doctorId: number, date: string, type = 'offline') {
    const doctor = await this.doctorRepo.findOne({
      where: { id: doctorId },
    });
    if (!doctor) throw new BadRequestException('Doctor not found');

    const schedule =
      type === 'online'
        ? this.isDoctorOnlineOnDate(doctor, date)
        : this.isDoctorWorkingOnDay(doctor, date);

    // Check if doctor works on this date
    if (!schedule) {
      return {
        doctorId,
        date,
        type,
        availableSlots: 0,
        consultLimitPerDay: doctor.consultLimitPerDay || 30,
        bookedCount: 0,
        message:
          type === 'online'
            ? `Doctor is not available online on ${this.getDayOfWeek(date)}`
            : `Doctor does not work on ${this.getDayOfWeek(date)}`,
      };
    }

    // Get appointment count for the day
    const bookedCount = (await this.getBookedTimes(doctorId, date, type))
      .length;
    const totalSlots = this.getScheduleSlotCount(schedule);
    const availableSlots = Math.max(0, totalSlots - bookedCount);

    return {
      doctorId,
      date,
      type,
      dayOfWeek: this.getDayOfWeek(date),
      workingHours: `${schedule.startTime} - ${schedule.endTime}`,
      availableSlots,
      consultLimitPerDay: totalSlots,
      bookedCount,
    };
  }
}
