/* eslint-disable @typescript-eslint/no-require-imports */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import {
  Injectable,
  NotFoundException,
  InternalServerErrorException,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import * as fs from 'fs';
import * as path from 'path';
import { Prescription } from './entities/prescription.entity';
import { CreatePrescriptionDto } from './dto/create-prescription.dto';
import { Doctor } from 'src/doctor/entities/doctor.entity';
import { Patients } from 'src/patient/entities/patient.entity';
import { Appointment } from 'src/appointments/entities/appointments.entity';

@Injectable()
export class PrescriptionService implements OnModuleInit {
  private readonly logger = new Logger(PrescriptionService.name);

  constructor(
    @InjectRepository(Prescription)
    private prescriptionRepo: Repository<Prescription>,

    @InjectRepository(Doctor)
    private doctorRepo: Repository<Doctor>,

    @InjectRepository(Patients)
    private patientRepo: Repository<Patients>,

    @InjectRepository(Appointment)
    private appointmentRepo: Repository<Appointment>,
  ) {}

  async onModuleInit() {
    await this.repairPrescriptionArrays();
  }

  private async repairPrescriptionArrays() {
    try {
      const prescriptions = await this.prescriptionRepo.find({
        where: [{ medicines: IsNull() }, { testsSuggested: IsNull() }],
      });

      let updatedCount = 0;

      for (const prescription of prescriptions) {
        const repairedFields: string[] = [];

        if (!prescription.medicines) {
          prescription.medicines = [];
          repairedFields.push('medicines');
        }

        if (!prescription.testsSuggested) {
          prescription.testsSuggested = [];
          repairedFields.push('testsSuggested');
        }

        if (repairedFields.length > 0) {
          await this.prescriptionRepo.save(prescription);
          updatedCount++;
          this.logger.log(
            `Repaired Prescription ID ${prescription.id}: ${repairedFields.join(
              ', ',
            )}`,
          );
        }
      }

      if (updatedCount > 0) {
        this.logger.log(
          `Repaired prescription array fields for ${updatedCount} prescription(s)`,
        );
      } else {
        this.logger.log(
          'All prescriptions already have medicines and testsSuggested arrays populated',
        );
      }
    } catch (error) {
      this.logger.error('Failed to repair prescription arrays:', error);
    }
  }

  async create(dto: CreatePrescriptionDto): Promise<Prescription> {
    const doctor = await this.doctorRepo.findOne({
      where: { id: dto.doctorId },
    });
    if (!doctor) throw new NotFoundException('Doctor not found');

    const patient = await this.patientRepo.findOne({
      where: { id: dto.patientId },
    });
    if (!patient) throw new NotFoundException('Patient not found');

    const pdfUrl = await this.generatePdf(dto, doctor, patient);

    const prescription = this.prescriptionRepo.create({
      appointmentId: dto.appointmentId,
      doctorId: dto.doctorId,
      patientId: dto.patientId,
      patientAge: dto.patientAge,
      diagnosis: dto.diagnosis,
      medicines: dto.medicines ?? [],
      testsSuggested: dto.testsSuggested ?? [],
      notes: dto.notes,
      pdfUrl,
    });

    const saved = await this.prescriptionRepo.save(prescription);

    // Link prescription to appointment
    await this.appointmentRepo.update(dto.appointmentId, {
      prescriptionId: saved.id,
    } as any);

    // Send FCM notification to patient if token provided
    if (dto.patientFcmToken) {
      await this.sendPushNotification(
        dto.patientFcmToken,
        'Prescription Ready',
        'Your doctor has written a prescription for you. Tap to view.',
      ).catch(() => {
        // Non-critical — swallow FCM errors
      });
    }

    return saved;
  }

  findAll() {
    return this.prescriptionRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: number): Promise<Prescription> {
    const prescription = await this.prescriptionRepo.findOne({ where: { id } });
    if (!prescription) throw new NotFoundException('Prescription not found');
    return prescription;
  }

  async findByAppointment(appointmentId: number): Promise<Prescription> {
    const prescription = await this.prescriptionRepo.findOne({
      where: { appointmentId },
    });
    if (!prescription)
      throw new NotFoundException(
        'Prescription not found for this appointment',
      );
    return prescription;
  }

  findByPatient(patientId: number) {
    return this.prescriptionRepo.find({
      where: { patientId },
      order: { createdAt: 'DESC' },
    });
  }

  async getPdfPath(id: number): Promise<string> {
    const prescription = await this.findOne(id);
    if (!prescription.pdfUrl)
      throw new NotFoundException('PDF not generated yet');

    // pdfUrl is stored as a relative path like "uploads/prescriptions/rx_123.pdf"
    const absolutePath = path.join(process.cwd(), prescription.pdfUrl);
    if (!fs.existsSync(absolutePath))
      throw new NotFoundException('PDF file not found on disk');

    return absolutePath;
  }

  // ─── PDF Generation ──────────────────────────────────────────────────────────

  private async generatePdf(
    dto: CreatePrescriptionDto,
    doctor: Doctor,
    patient: Patients,
  ): Promise<string> {
    try {
      // Ensure uploads directory exists
      const uploadDir = path.join(process.cwd(), 'uploads', 'prescriptions');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `rx_${dto.appointmentId}_${Date.now()}.pdf`;
      const filePath = path.join(uploadDir, filename);
      const relativePath = `uploads/prescriptions/${filename}`;

      // Dynamically require pdfkit to avoid module issues
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const PDFDocument = require('pdfkit') as any;
      const doc = new PDFDocument({ margin: 50, size: 'A4' });

      const writeStream = fs.createWriteStream(filePath);
      doc.pipe(writeStream);

      this.buildPdfContent(doc, dto, doctor, patient);

      doc.end();

      // Wait for the write stream to finish
      await new Promise<void>((resolve, reject) => {
        writeStream.on('finish', resolve);
        writeStream.on('error', reject);
      });

      return relativePath;
    } catch {
      throw new InternalServerErrorException('Failed to generate PDF');
    }
  }

  private buildPdfContent(
    doc: any,
    dto: CreatePrescriptionDto,
    doctor: Doctor,
    patient: Patients,
  ) {
    const primaryColor = '#1E88E5';
    const darkColor = '#1A1A1A';
    const grayColor = '#666666';
    const lightGray = '#F5F5F5';
    const pageWidth = doc.page.width - 100; // margins

    // ── HEADER ─────────────────────────────────────────────────────────────────
    doc.rect(0, 0, doc.page.width, 120).fill(primaryColor);

    doc
      .fontSize(22)
      .font('Helvetica-Bold')
      .fillColor('white')
      .text('HealthCare+', 50, 30);

    doc
      .fontSize(10)
      .font('Helvetica')
      .fillColor('white')
      .text('Digital Medical Prescription', 50, 58);

    doc
      .fontSize(10)
      .font('Helvetica')
      .fillColor('white')
      .text(
        `Dr. ${doctor.name}${doctor.degrees ? ` | ${doctor.degrees}` : ''}`,
        50,
        75,
      );

    if (doctor.specialty) {
      doc
        .fontSize(9)
        .fillColor('white')
        .text(`Specialty: ${doctor.specialty}`, 50, 90);
    }

    // Date on right side
    const dateStr = new Date().toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
    doc
      .fontSize(10)
      .font('Helvetica')
      .fillColor('white')
      .text(dateStr, 350, 40, {
        align: 'right',
        width: 200,
      });

    doc.moveDown(5);

    // ── PATIENT INFO ───────────────────────────────────────────────────────────
    doc
      .rect(50, 130, pageWidth, 60)
      .fillAndStroke(lightGray, '#E0E0E0')
      .fillColor(darkColor);

    doc
      .fontSize(11)
      .font('Helvetica-Bold')
      .fillColor(primaryColor)
      .text('PATIENT INFORMATION', 65, 140);

    doc
      .fontSize(10)
      .font('Helvetica')
      .fillColor(darkColor)
      .text(`Name: ${patient.name}`, 65, 156);

    if (dto.patientAge) {
      doc
        .fontSize(10)
        .font('Helvetica')
        .fillColor(darkColor)
        .text(`Age: ${dto.patientAge} years`, 250, 156);
    }

    if (patient.phone) {
      doc
        .fontSize(10)
        .font('Helvetica')
        .fillColor(darkColor)
        .text(`Phone: ${patient.phone}`, 65, 170);
    }

    doc.moveDown(5);

    // ── DIAGNOSIS ──────────────────────────────────────────────────────────────
    if (dto.diagnosis) {
      doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .fillColor(primaryColor)
        .text('Diagnosis / Chief Complaint', 50, 205);

      doc
        .moveTo(50, 220)
        .lineTo(50 + pageWidth, 220)
        .strokeColor(primaryColor)
        .stroke();

      doc
        .fontSize(10)
        .font('Helvetica')
        .fillColor(darkColor)
        .text(dto.diagnosis, 50, 226, { width: pageWidth });
    }

    let yPos = dto.diagnosis ? 260 : 205;

    // ── MEDICINES ──────────────────────────────────────────────────────────────
    if (dto.medicines && dto.medicines.length > 0) {
      doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .fillColor(primaryColor)
        .text('Prescribed Medicines', 50, yPos);

      doc
        .moveTo(50, yPos + 15)
        .lineTo(50 + pageWidth, yPos + 15)
        .strokeColor(primaryColor)
        .stroke();

      yPos += 20;

      // Table header
      const colWidths = [170, 80, 130, 100];
      const headers = ['Medicine Name', 'Dose', 'Frequency', 'Duration'];
      const colX = [50, 220, 300, 430];

      doc.rect(50, yPos, pageWidth, 20).fill('#E3F2FD').fillColor(darkColor);

      headers.forEach((h, i) => {
        doc
          .fontSize(9)
          .font('Helvetica-Bold')
          .fillColor(darkColor)
          .text(h, colX[i], yPos + 5, { width: colWidths[i] });
      });

      yPos += 20;

      dto.medicines.forEach((med, idx) => {
        const rowBg = idx % 2 === 0 ? 'white' : lightGray;
        doc.rect(50, yPos, pageWidth, 20).fill(rowBg).fillColor(darkColor);

        const values = [med.name, med.dose, med.frequency, med.duration];
        values.forEach((v, i) => {
          doc
            .fontSize(9)
            .font('Helvetica')
            .fillColor(darkColor)
            .text(v ?? '-', colX[i], yPos + 5, { width: colWidths[i] });
        });

        yPos += 20;
      });

      yPos += 10;
    }

    // ── TESTS SUGGESTED ────────────────────────────────────────────────────────
    if (dto.testsSuggested && dto.testsSuggested.length > 0) {
      doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .fillColor(primaryColor)
        .text('Diagnostic Tests Suggested', 50, yPos);

      doc
        .moveTo(50, yPos + 15)
        .lineTo(50 + pageWidth, yPos + 15)
        .strokeColor(primaryColor)
        .stroke();

      yPos += 22;

      dto.testsSuggested.forEach((test) => {
        doc
          .fontSize(10)
          .font('Helvetica')
          .fillColor(darkColor)
          .text(`• ${test}`, 60, yPos);
        yPos += 16;
      });

      yPos += 8;
    }

    // ── NOTES ──────────────────────────────────────────────────────────────────
    if (dto.notes) {
      doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .fillColor(primaryColor)
        .text("Doctor's Notes / Advice", 50, yPos);

      doc
        .moveTo(50, yPos + 15)
        .lineTo(50 + pageWidth, yPos + 15)
        .strokeColor(primaryColor)
        .stroke();

      yPos += 22;

      doc
        .fontSize(10)
        .font('Helvetica')
        .fillColor(darkColor)
        .text(dto.notes, 50, yPos, { width: pageWidth });
    }

    // ── FOOTER ─────────────────────────────────────────────────────────────────
    const footerY = doc.page.height - 80;

    doc
      .moveTo(50, footerY)
      .lineTo(50 + pageWidth, footerY)
      .strokeColor('#CCCCCC')
      .stroke();

    doc
      .fontSize(9)
      .font('Helvetica-Bold')
      .fillColor(darkColor)
      .text(`Dr. ${doctor.name}`, 50, footerY + 8);

    if (doctor.degrees) {
      doc
        .fontSize(8)
        .font('Helvetica')
        .fillColor(grayColor)
        .text(doctor.degrees, 50, footerY + 20);
    }

    doc
      .fontSize(7)
      .font('Helvetica')
      .fillColor(grayColor)
      .text(
        'This is a digitally generated prescription. Valid only when issued through HealthCare+ system.',
        50,
        footerY + 48,
        { width: pageWidth, align: 'center' },
      );
  }

  // ─── FCM Push Notification ────────────────────────────────────────────────

  private async sendPushNotification(
    fcmToken: string,
    title: string,
    body: string,
  ): Promise<void> {
    const fcmServerKey = process.env.FCM_SERVER_KEY;
    if (!fcmServerKey) return;

    const payload = {
      to: fcmToken,
      notification: { title, body },
      data: { type: 'prescription_ready' },
    };

    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${fcmServerKey}`,
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(`FCM error: ${response.status}`);
    }
  }
}
