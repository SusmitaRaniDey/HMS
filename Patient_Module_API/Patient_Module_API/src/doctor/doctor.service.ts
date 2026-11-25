import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Appointment } from 'src/appointments/entities/appointments.entity';
import { Repository, MoreThanOrEqual, IsNull } from 'typeorm';
import { ChangePasswordDto, DoctorLoginDto } from './dto/doctor-auth.dto';
import { DaySchedule, Doctor, OnlineSchedule } from './entities/doctor.entity';

@Injectable()
export class DoctorService implements OnModuleInit {
  private readonly logger = new Logger(DoctorService.name);

  constructor(
    @InjectRepository(Doctor)
    private doctorRepo: Repository<Doctor>,
    @InjectRepository(Appointment)
    private appointmentRepo: Repository<Appointment>,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  /**
   * Runs on application startup to repair missing schedule data without
   * overwriting existing non-empty schedules.
   */
  async onModuleInit() {
    // Doctor data is administrator-owned. Application bootstrap must be
    // read-only; repairs/backfills belong in explicit, reviewed migrations.
  }

  /**
   * Legacy helper retained for compatibility. It only repairs the numeric
   * availability field; schedules must always come from the admin.
   */
  private async seedDoctorDefaults() {
    try {
      // Find all doctors with null available_slots or null workingDays
      const doctors = await this.doctorRepo.find();

      let updatedCount = 0;
      for (const doctor of doctors) {
        let needsUpdate = false;

        if (
          doctor.available_slots === null ||
          doctor.available_slots === undefined
        ) {
          doctor.available_slots = doctor.consultLimitPerDay || 30;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await this.doctorRepo.save(doctor);
          updatedCount++;
          this.logger.log(
            `Seeded defaults for Doctor ID ${doctor.id} (${doctor.name}): available_slots=${doctor.available_slots}, workingDays set`,
          );
        }
      }

      if (updatedCount > 0) {
        this.logger.log(
          `✅ Seeded default values for ${updatedCount} doctor(s)`,
        );
      } else {
        this.logger.log(
          '✅ All doctors already have available_slots and workingDays populated',
        );
      }
    } catch (error) {
      this.logger.error('Failed to seed doctor defaults:', error);
    }
  }

  private async repairNonScheduleDefaults() {
    try {
      const doctors = await this.doctorRepo.find();
      let updatedCount = 0;

      for (const doctor of doctors) {
        const repairedFields: string[] = [];

        if (
          doctor.available_slots === null ||
          doctor.available_slots === undefined
        ) {
          doctor.available_slots = doctor.consultLimitPerDay || 30;
          repairedFields.push('available_slots');
        }

        if (repairedFields.length > 0) {
          await this.doctorRepo.save(doctor);
          updatedCount++;
          this.logger.log(
            `Repaired Doctor ID ${doctor.id} (${doctor.name}): ${repairedFields.join(
              ', ',
            )}`,
          );
        }
      }

      if (updatedCount > 0) {
        this.logger.log(
          `Seeded/repaired schedule values for ${updatedCount} doctor(s)`,
        );
      } else {
        this.logger.log(
          'All doctors already have available_slots populated',
        );
      }
    } catch (error) {
      this.logger.error('Failed to repair doctor schedules:', error);
    }
  }

  private cloneSchedule(
    schedule: Array<DaySchedule | OnlineSchedule>,
  ): Array<DaySchedule | OnlineSchedule> {
    return schedule.map((slot) => ({
      day: slot.day,
      startTime: slot.startTime,
      endTime: slot.endTime,
    }));
  }

  // ============= Authentication =============
  async loginDoctor(loginDto: DoctorLoginDto) {
    const doctor = await this.doctorRepo
      .createQueryBuilder('doctor')
      .addSelect('doctor.password')
      .where('doctor.email = :email', { email: loginDto.email })
      .getOne();

    if (!doctor) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      doctor.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // Generate JWT token
    const token = this.generateToken(doctor);

    return {
      message: 'Login successful',
      doctor: {
        id: doctor.id,
        name: doctor.name,
        email: doctor.email,
        specialty: doctor.specialty,
        profilePic: doctor.profilePic,
      },
      accessToken: token,
    };
  }

  private generateToken(doctor: Doctor): string {
    const payload = {
      id: doctor.id,
      email: doctor.email,
      name: doctor.name,
      role: 'doctor',
    };
    return this.jwtService.sign(payload, {
      secret:
        this.configService.get('DOCTOR_ACCESS_TOKEN_SEC') ||
        this.configService.get('ACCESS_TOKEN_SEC'),
      expiresIn: '12h',
    });
  }

  // ============= Profile Management =============
  async getDoctorProfile(doctorId: number) {
    const doctor = await this.doctorRepo.findOne({ where: { id: doctorId } });
    if (!doctor) throw new NotFoundException('Doctor not found');

    return {
      id: doctor.id,
      name: doctor.name,
      email: doctor.email,
      phone: doctor.phone,
      specialty: doctor.specialty,
      degrees: doctor.degrees,
      experience: doctor.experience,
      working_at: doctor.working_at,
      fee: doctor.fee,
      onlineFee: doctor.onlineFee,
      offlineFee: doctor.offlineFee,
      profilePic: doctor.profilePic,
      biography: doctor.biography,
      languages: doctor.languages,
      available_slots: doctor.available_slots,
      slots: doctor.available_slots, // Mapping to 'slots' if frontend expects it
      workingDays: doctor.workingDays,
      onlineSchedule: doctor.onlineSchedule,
      consultLimitPerDay: doctor.consultLimitPerDay,
      createdAt: doctor.createdAt,
    };
  }

  async changePassword(doctorId: number, changePasswordDto: ChangePasswordDto) {
    const doctor = await this.doctorRepo
      .createQueryBuilder('doctor')
      .addSelect('doctor.password')
      .where('doctor.id = :id', { id: doctorId })
      .getOne();
    if (!doctor) throw new NotFoundException('Doctor not found');

    // Verify old password
    const isPasswordValid = await bcrypt.compare(
      changePasswordDto.oldPassword,
      doctor.password,
    );
    if (!isPasswordValid) {
      throw new BadRequestException('Old password is incorrect');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(changePasswordDto.newPassword, 10);
    doctor.password = hashedPassword;
    await this.doctorRepo.save(doctor);

    return { message: 'Password changed successfully' };
  }

  // ============= Appointments =============
  async getDoctorAppointments(
    doctorId: number,
    page: number = 1,
    limit: number = 20,
    status?: string,
  ) {
    const where: Record<string, any> = { doctorId };
    if (status) where['status'] = status;

    const [appointments, total] = await this.appointmentRepo.findAndCount({
      where: where as any, // eslint-disable-line
      relations: ['patient'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return {
      data: appointments.map((a) => this.mapAppointmentResponse(a)),
      total,
      page,
      limit,
    };
  }

  private mapAppointmentResponse(a: Appointment) {
    return {
      id: a.id,
      date: a.date,
      serialNumber: a.serialNumber,
      status: a.status,
      type: a.type,
      zoomMeetingId: a.zoomMeetingId,
      zoomJoinUrl: null,
      zoomStartUrl: null,
      zoomPassword: a.zoomPassword,
      meetingStatus: a.meetingStatus,
      startTime: a.startTime,
      prescriptionId: a.prescriptionId,
      doctorId: a.doctorId,
      patientId: a.patientId,
      patient: {
        id: a.patient?.id,
        name: a.patient?.name,
        phone: a.patient?.phone,
        email: a.patient?.email,
      },
      createdAt: a.createdAt,
    };
  }

  async getPendingAppointments(doctorId: number) {
    const appointments = await this.appointmentRepo.find({
      where: { doctorId, status: 'pending' },
      relations: ['patient'],
      order: { createdAt: 'ASC' },
    });

    return appointments.map((a) => this.mapAppointmentResponse(a));
  }

  async getTodayAppointments(doctorId: number) {
    const today = new Date().toISOString().split('T')[0];

    const appointments = await this.appointmentRepo.find({
      where: { doctorId, date: today },
      relations: ['patient'],
      order: { serialNumber: 'ASC' },
    });

    return appointments.map((a) => this.mapAppointmentResponse(a));
  }

  async getUpcomingAppointments(doctorId: number) {
    const today = new Date().toISOString().split('T')[0];

    const appointments = await this.appointmentRepo.find({
      where: {
        doctorId,
        status: 'confirmed',
        date: MoreThanOrEqual(today),
      },
      relations: ['patient'],
      order: { date: 'ASC', serialNumber: 'ASC' },
    });

    return appointments.map((a) => this.mapAppointmentResponse(a));
  }

  async getCancelledAppointments(doctorId: number) {
    const appointments = await this.appointmentRepo.find({
      where: { doctorId, status: 'cancelled' },
      relations: ['patient'],
      order: { date: 'ASC', serialNumber: 'ASC' },
    });

    return appointments.map((a) => this.mapAppointmentResponse(a));
  }

  async getConfirmedAppointments(doctorId: number) {
    const appointments = await this.appointmentRepo.find({
      where: { doctorId, status: 'confirmed' },
      relations: ['patient'],
      order: { date: 'ASC', serialNumber: 'ASC' },
    });

    return appointments.map((a) => this.mapAppointmentResponse(a));
  }

  async getDoctorAppointmentHistory(
    doctorId: number,
    page: number = 1,
    limit: number = 20,
  ) {
    const today = this.getLocalDateString();
    const [appointments, total] = await this.appointmentRepo
      .createQueryBuilder('appointment')
      .leftJoinAndSelect('appointment.patient', 'patient')
      .where('appointment.doctorId = :doctorId', { doctorId })
      .andWhere(
        '(appointment.status = :completed OR appointment.date < :today)',
        { completed: 'completed', today },
      )
      .orderBy('appointment.date', 'DESC')
      .addOrderBy('appointment.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      data: appointments.map((a) => this.mapAppointmentResponse(a)),
      total,
      page,
      limit,
    };
  }

  async getAppointmentDetails(doctorId: number, appointmentId: number) {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId, doctorId },
      relations: ['patient', 'doctor'],
    });

    if (!appointment) throw new NotFoundException('Appointment not found');

    return {
      id: appointment.id,
      date: appointment.date,
      serialNumber: appointment.serialNumber,
      status: appointment.status,
      type: appointment.type,
      zoomMeetingId: appointment.zoomMeetingId,
      zoomJoinUrl: null,
      zoomStartUrl: null,
      zoomPassword: appointment.zoomPassword,
      meetingStatus: appointment.meetingStatus,
      startTime: appointment.startTime,
      prescriptionId: appointment.prescriptionId,
      doctorId: appointment.doctorId,
      patientId: appointment.patientId,
      cancellationReason: appointment.cancellationReason,
      patient: {
        id: appointment.patient?.id,
        name: appointment.patient?.name,
        phone: appointment.patient?.phone,
        email: appointment.patient?.email,
      },
      doctor: {
        id: appointment.doctor?.id,
        name: appointment.doctor?.name,
        specialty: appointment.doctor?.specialty,
      },
      createdAt: appointment.createdAt,
      updatedAt: appointment.updatedAt,
    };
  }

  async getAppointmentMeetingStartUrl(doctorId: number, appointmentId: number) {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId, doctorId },
    });

    if (!appointment) throw new NotFoundException('Appointment not found');
    this.validateMeetingAccessDate(appointment);

    if (!appointment.meetingStatus || appointment.meetingStatus === 'scheduled') {
      appointment.meetingStatus = 'started';
      await this.appointmentRepo.save(appointment);
    }

    return {
      meetingUrl: appointment.zoomStartUrl || appointment.zoomJoinUrl,
      zoomPassword: appointment.zoomPassword,
    };
  }

  private validateMeetingAccessDate(appointment: Appointment) {
    if (appointment.type !== 'online') {
      throw new BadRequestException('This appointment is not an online meeting.');
    }

    if (!appointment.zoomStartUrl && !appointment.zoomJoinUrl) {
      throw new BadRequestException('Meeting link is not available yet.');
    }

    const appointmentDate = this.normalizeDate(appointment.date);
    const today = this.getLocalDateString();

    if (today > appointmentDate) {
      throw new BadRequestException(
        'This meeting has ended. The appointment time is over.',
      );
    }

    if (today < appointmentDate) {
      throw new BadRequestException(
        'This meeting is available only on the appointment date.',
      );
    }
  }

  private getLocalDateString(date = new Date()) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private normalizeDate(date: string) {
    return date.includes('T') ? date.split('T')[0] : date;
  }
}
