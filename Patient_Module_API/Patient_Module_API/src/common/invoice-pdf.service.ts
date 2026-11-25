import { Injectable } from '@nestjs/common';

export interface InvoicePdfData {
  invoiceNumber: string;
  invoiceFor: string;
  patientName: string;
  patientPhone: string;
  patientEmail: string;
  serviceDetails: { label: string; value: string }[];
  paymentMethod: string;
  paymentStatus: string;
  isPaid: string;
  amount: number;
  transactionId?: string | null;
  bankTransactionId?: string | null;
  createdAt?: Date | null;
}

/**
 * Shared invoice PDF renderer, extracted from the logic that used to live
 * as PatientService.buildInvoicePdf (patient/diagnostic invoices) so the
 * Billing module can reuse the exact same layout instead of duplicating
 * ~200 lines of pdfkit drawing code. Rendering output is unchanged from
 * the original private method.
 */
@Injectable()
export class InvoicePdfService {
  generate(data: InvoicePdfData): Promise<Buffer> {
    /* eslint-disable @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment */
    return new Promise((resolve, reject) => {
      const PDFDocument = require('pdfkit') as any;
      const doc = new PDFDocument({ margin: 50, size: 'A4' });

      const chunks: Buffer[] = [];
      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', (err: Error) => reject(err));

      const primaryColor = '#1E88E5';
      const darkColor = '#1A1A1A';
      const grayColor = '#666666';
      const lightGray = '#F5F5F5';
      const pageWidth = doc.page.width - 100;

      // ── HEADER ─────────────────────────────────────────────────────────────
      doc.rect(0, 0, doc.page.width, 110).fill(primaryColor);

      doc
        .fontSize(22)
        .font('Helvetica-Bold')
        .fillColor('white')
        .text('HealthGrid', 50, 25);
      doc
        .fontSize(11)
        .font('Helvetica')
        .fillColor('white')
        .text('PAYMENT INVOICE', 50, 52);
      doc
        .fontSize(9)
        .font('Helvetica')
        .fillColor('white')
        .text(data.invoiceFor, 50, 67);

      const dateStr = (data.createdAt ?? new Date()).toLocaleDateString(
        'en-US',
        { year: 'numeric', month: 'long', day: 'numeric' },
      );
      doc
        .fontSize(9)
        .font('Helvetica')
        .fillColor('white')
        .text(`Invoice No: ${data.invoiceNumber}`, 350, 30, {
          align: 'right',
          width: 200,
        })
        .text(`Date: ${dateStr}`, 350, 44, { align: 'right', width: 200 });

      // ── BILLED TO ──────────────────────────────────────────────────────────
      let yPos = 125;
      doc
        .rect(50, yPos, pageWidth, 68)
        .fillAndStroke(lightGray, '#E0E0E0')
        .fillColor(darkColor);

      doc
        .fontSize(10)
        .font('Helvetica-Bold')
        .fillColor(primaryColor)
        .text('BILLED TO', 65, yPos + 8);
      doc
        .fontSize(10)
        .font('Helvetica')
        .fillColor(darkColor)
        .text(`Name:  ${data.patientName}`, 65, yPos + 24);
      if (data.patientPhone) {
        doc.text(`Phone: ${data.patientPhone}`, 65, yPos + 38);
      }
      if (data.patientEmail) {
        doc.text(`Email: ${data.patientEmail}`, 65, yPos + 52);
      }

      // ── SERVICE DETAILS ────────────────────────────────────────────────────
      yPos += 84;
      doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .fillColor(primaryColor)
        .text('Service Details', 50, yPos);
      doc
        .moveTo(50, yPos + 16)
        .lineTo(50 + pageWidth, yPos + 16)
        .strokeColor(primaryColor)
        .stroke();
      yPos += 22;

      data.serviceDetails.forEach((item, idx) => {
        const rowBg = idx % 2 === 0 ? 'white' : lightGray;
        doc.rect(50, yPos, pageWidth, 22).fill(rowBg);
        doc
          .fontSize(10)
          .font('Helvetica-Bold')
          .fillColor(darkColor)
          .text(item.label, 60, yPos + 5, { width: 160 });
        doc
          .fontSize(10)
          .font('Helvetica')
          .fillColor(darkColor)
          .text(item.value, 220, yPos + 5, { width: pageWidth - 175 });
        yPos += 22;
      });

      // ── PAYMENT DETAILS ────────────────────────────────────────────────────
      yPos += 16;
      doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .fillColor(primaryColor)
        .text('Payment Details', 50, yPos);
      doc
        .moveTo(50, yPos + 16)
        .lineTo(50 + pageWidth, yPos + 16)
        .strokeColor(primaryColor)
        .stroke();
      yPos += 22;

      const methodDisplay =
        data.paymentMethod === 'pay_now'
          ? 'Online Payment'
          : data.paymentMethod === 'pay_in_hospital'
            ? 'Pay at Hospital'
            : data.paymentMethod;

      const statusDisplay =
        data.paymentStatus.charAt(0).toUpperCase() +
        data.paymentStatus.slice(1);

      const payRows: { label: string; value: string }[] = [
        { label: 'Payment Method', value: methodDisplay },
        { label: 'Payment Status', value: statusDisplay },
        { label: 'Amount', value: `BDT ${data.amount.toFixed(0)}` },
      ];
      if (data.transactionId)
        payRows.push({ label: 'Transaction ID', value: data.transactionId });
      if (data.bankTransactionId)
        payRows.push({
          label: 'Bank Transaction ID',
          value: data.bankTransactionId,
        });

      payRows.forEach((row, idx) => {
        const rowBg = idx % 2 === 0 ? 'white' : lightGray;
        doc.rect(50, yPos, pageWidth, 22).fill(rowBg);
        doc
          .fontSize(10)
          .font('Helvetica-Bold')
          .fillColor(darkColor)
          .text(row.label, 60, yPos + 5, { width: 160 });
        doc
          .fontSize(10)
          .font('Helvetica')
          .fillColor(darkColor)
          .text(row.value, 220, yPos + 5, { width: pageWidth - 175 });
        yPos += 22;
      });

      // ── TOTAL AMOUNT BOX ───────────────────────────────────────────────────
      yPos += 16;
      const isPaidBg = data.isPaid === 'paid' ? '#E8F5E9' : '#FFF3E0';
      const isPaidBorder = data.isPaid === 'paid' ? '#4CAF50' : '#FF9800';
      const isPaidTextColor = data.isPaid === 'paid' ? '#2E7D32' : '#E65100';
      const paidLabel = data.isPaid === 'paid' ? 'PAID' : 'PAYMENT PENDING';
      doc
        .rect(50, yPos, pageWidth, 48)
        .fillAndStroke(isPaidBg, isPaidBorder);
      doc
        .fontSize(13)
        .font('Helvetica-Bold')
        .fillColor(isPaidTextColor)
        .text(
          `Total: BDT ${data.amount.toFixed(0)}     [${paidLabel}]`,
          60,
          yPos + 16,
          { width: pageWidth - 20, align: 'center' },
        );

      // ── FOOTER ─────────────────────────────────────────────────────────────
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
        .text('HealthGrid', 50, footerY + 10);
      doc
        .fontSize(8)
        .font('Helvetica')
        .fillColor(grayColor)
        .text(
          'This is a system-generated invoice. Thank you for choosing HealthGrid.',
          50,
          footerY + 24,
          { width: pageWidth, align: 'center' },
        );

      doc.end();
    });
    /* eslint-enable */
  }
}
