// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as web_html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/patient_history_controller.dart';
import '../../models/prescription_history_model.dart';
import '../../utils/app_colors.dart';

class PatientHistoryDialog extends StatelessWidget {
  final PatientHistoryController controller;

  const PatientHistoryDialog({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1140,
          maxHeight: screenH * 0.88,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        children: [
          const Icon(Icons.history_edu, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Patient History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${controller.patientName.value}  •  ${controller.patientPhone.value}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                )),
          ),
          // Print All button — only shown when there are prescriptions
          Obx(() {
            if (controller.prescriptions.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _printAll,
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Print All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          }),
          // Close button
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.prescriptions.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu_outlined,
                  size: 72, color: AppColors.textHint),
              SizedBox(height: 16),
              Text(
                'No prescription history found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This patient has no recorded visits yet.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: controller.prescriptions.length,
        itemBuilder: (_, index) =>
            _buildVisitBlock(controller.prescriptions[index], index + 1),
      );
    });
  }

  // ─── Visit block ─────────────────────────────────────────────────────────────

  Widget _buildVisitBlock(PrescriptionHistoryModel rx, int visitNumber) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(rx.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Visit header with per-visit Print button ──────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Visit $visitNumber  •  $dateStr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (rx.doctor != null)
                        Text(
                          'Dr. ${rx.doctor!.name}  |  ${rx.doctor!.specialty}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Per-visit print button
                OutlinedButton.icon(
                  onPressed: () => _printVisit(rx, visitNumber),
                  icon: const Icon(Icons.print,
                      size: 14, color: Colors.white),
                  label: const Text(
                    'Print Visit',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          // ── Visit content ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Details
                _buildSection(
                  icon: Icons.person,
                  title: 'Patient Details',
                  color: AppColors.info,
                  child: _buildInfoGrid([
                    _InfoItem('Name', rx.patient.name),
                    _InfoItem('Phone', rx.patient.phone),
                    if (rx.patientAge != null && rx.patientAge!.isNotEmpty)
                      _InfoItem('Age', '${rx.patientAge} years'),
                  ]),
                ),

                const SizedBox(height: 16),

                // Doctor Details
                if (rx.doctor != null) ...[
                  _buildSection(
                    icon: Icons.local_hospital,
                    title: 'Doctor Details',
                    color: AppColors.secondary,
                    child: _buildInfoGrid([
                      _InfoItem('Name', 'Dr. ${rx.doctor!.name}'),
                      _InfoItem('Specialty', rx.doctor!.specialty),
                      if (rx.doctor!.degrees != null &&
                          rx.doctor!.degrees!.isNotEmpty)
                        _InfoItem('Degrees', rx.doctor!.degrees!),
                      if (rx.doctor!.phone != null &&
                          rx.doctor!.phone!.isNotEmpty)
                        _InfoItem('Contact', rx.doctor!.phone!),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Diagnosis
                if (rx.diagnosis != null && rx.diagnosis!.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.healing,
                    title: 'Diagnosis',
                    color: AppColors.warning,
                    child: Text(rx.diagnosis!,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tests Suggested
                if (rx.testsSuggested.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.science,
                    title: 'Tests Ordered',
                    color: AppColors.completed,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rx.testsSuggested
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(children: [
                                  const Icon(Icons.circle,
                                      size: 7,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(t,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                ]),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Medicines
                if (rx.medicines.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.medication,
                    title: 'Prescribed Medicines',
                    color: AppColors.error,
                    child: _buildMedicinesTable(rx.medicines),
                  ),
                ],

                // Doctor Notes
                if (rx.notes != null && rx.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    icon: Icons.notes,
                    title: "Doctor's Notes",
                    color: AppColors.textSecondary,
                    child: Text(rx.notes!,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section helpers ─────────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return Wrap(
      spacing: 32,
      runSpacing: 10,
      children: items
          .map((item) => SizedBox(
                width: 260,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text('${item.label}:',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: Text(item.value,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMedicinesTable(List<MedicineDetail> medicines) {
    return Table(
      border: TableBorder.all(color: AppColors.border, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE3F2FD)),
          children: [
            _tableHeader('Medicine'),
            _tableHeader('Dose'),
            _tableHeader('Frequency'),
            _tableHeader('Duration'),
          ],
        ),
        ...medicines.map((m) => TableRow(children: [
              _tableCell(m.name),
              _tableCell(m.dose),
              _tableCell(m.frequency),
              _tableCell(m.duration),
            ])),
      ],
    );
  }

  Widget _tableHeader(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1A1A1A))),
      );

  Widget _tableCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text.isEmpty ? '-' : text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary)),
      );

  // ─── Print ───────────────────────────────────────────────────────────────────

  void _printAll() {
    _openPrintWindow(_buildPrintHtml(
      controller.patientName.value,
      controller.patientPhone.value,
      controller.prescriptions,
      totalVisits: controller.prescriptions.length,
    ));
  }

  void _printVisit(PrescriptionHistoryModel rx, int visitNumber) {
    _openPrintWindow(_buildPrintHtml(
      controller.patientName.value,
      controller.patientPhone.value,
      [rx],
      startVisitNumber: visitNumber,
      totalVisits: controller.prescriptions.length,
    ));
  }

  void _openPrintWindow(String htmlContent) {
    final blob = web_html.Blob([htmlContent], 'text/html');
    final url = web_html.Url.createObjectUrl(blob);
    web_html.window.open(url, '_blank');
  }

  String _buildPrintHtml(
    String patientName,
    String patientPhone,
    List<PrescriptionHistoryModel> prescriptions, {
    int startVisitNumber = 1,
    int? totalVisits,
  }) {
    final total = totalVisits ?? prescriptions.length;
    final buf = StringBuffer();

    buf.write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Patient History – $patientName</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: Arial, Helvetica, sans-serif; font-size: 13px;
           color: #1a1a1a; background: #fff; padding: 24px; }
    h1 { font-size: 20px; color: #3B82F6; margin-bottom: 4px; }
    .subtitle { color: #64748B; margin-bottom: 20px; font-size: 13px; }
    .visit-block { border: 1px solid #e2e8f0; border-radius: 8px;
                   margin-bottom: 28px; overflow: hidden; }
    .visit-header { background: linear-gradient(135deg,#3B82F6,#1E40AF);
                    color:#fff; padding:12px 16px;
                    display:flex; justify-content:space-between; align-items:center; }
    .visit-num { font-size:15px; font-weight:700; }
    .visit-doc { font-size:12px; opacity:.9; }
    .visit-body { padding:16px; }
    .section { margin-bottom:14px; }
    .section-title { font-weight:700; font-size:13px; margin-bottom:6px; }
    .section-box { background:#f8fafc; border:1px solid #e2e8f0;
                   border-radius:6px; padding:10px 12px; }
    .info-grid { display:flex; flex-wrap:wrap; gap:8px 24px; }
    .info-item { display:flex; gap:6px; min-width:200px; }
    .info-label { color:#64748b; min-width:76px; flex-shrink:0; }
    .info-value { font-weight:600; }
    ul { margin-left:18px; }
    li { margin-bottom:3px; }
    table { width:100%; border-collapse:collapse; font-size:12px; }
    th { background:#e3f2fd; font-weight:700; text-align:left; }
    th, td { padding:8px 12px; border:1px solid #e2e8f0; }
    tr:nth-child(even) td { background:#f8fafc; }
    .print-btn { margin-bottom:20px; }
    button { background:#3B82F6; color:#fff; border:none;
             padding:10px 24px; border-radius:6px; font-size:14px; cursor:pointer; }
    button:hover { background:#1E40AF; }
    .page-label { text-align:right; font-size:11px; color:#888;
                  padding-top:8px; border-top:1px solid #e2e8f0; margin-top:12px; }
    @media print {
      .no-print { display:none !important; }
      body { padding:12px; }
      .visit-block { page-break-inside:avoid; }
      @page { @bottom-right { content: ""; } }
    }
  </style>
</head>
<body>
  <div class="no-print print-btn">
    <h1>Patient History</h1>
    <p class="subtitle">$patientName &nbsp;|&nbsp; $patientPhone</p>
    <button onclick="window.print()">Print</button>
  </div>
''');

    if (prescriptions.isEmpty) {
      buf.write('<p>No prescription history found.</p>');
    }

    for (int i = 0; i < prescriptions.length; i++) {
      final rx = prescriptions[i];
      final date = DateFormat('dd MMM yyyy, hh:mm a').format(rx.createdAt);
      final doctorName =
          rx.doctor != null ? 'Dr. ${rx.doctor!.name}' : 'Unknown Doctor';

      buf.write('''
  <div class="visit-block">
    <div class="visit-header">
      <span class="visit-num">Visit ${startVisitNumber + i} &bull; $date</span>
      <span class="visit-doc">$doctorName</span>
    </div>
    <div class="visit-body">
''');

      // Patient Details
      buf.write('''
      <div class="section">
        <div class="section-title" style="color:#3B82F6">Patient Details</div>
        <div class="section-box"><div class="info-grid">
          <div class="info-item"><span class="info-label">Name:</span>
            <span class="info-value">${rx.patient.name}</span></div>
          <div class="info-item"><span class="info-label">Phone:</span>
            <span class="info-value">${rx.patient.phone}</span></div>
''');
      if (rx.patientAge != null && rx.patientAge!.isNotEmpty) {
        buf.write('''
          <div class="info-item"><span class="info-label">Age:</span>
            <span class="info-value">${rx.patientAge} years</span></div>
''');
      }
      buf.write('        </div></div></div>\n');

      // Doctor Details
      if (rx.doctor != null) {
        buf.write('''
      <div class="section">
        <div class="section-title" style="color:#10B981">Doctor Details</div>
        <div class="section-box"><div class="info-grid">
          <div class="info-item"><span class="info-label">Name:</span>
            <span class="info-value">Dr. ${rx.doctor!.name}</span></div>
          <div class="info-item"><span class="info-label">Specialty:</span>
            <span class="info-value">${rx.doctor!.specialty}</span></div>
''');
        if (rx.doctor!.degrees != null && rx.doctor!.degrees!.isNotEmpty) {
          buf.write('''
          <div class="info-item"><span class="info-label">Degrees:</span>
            <span class="info-value">${rx.doctor!.degrees}</span></div>
''');
        }
        if (rx.doctor!.phone != null && rx.doctor!.phone!.isNotEmpty) {
          buf.write('''
          <div class="info-item"><span class="info-label">Contact:</span>
            <span class="info-value">${rx.doctor!.phone}</span></div>
''');
        }
        buf.write('        </div></div></div>\n');
      }

      // Diagnosis
      if (rx.diagnosis != null && rx.diagnosis!.isNotEmpty) {
        buf.write('''
      <div class="section">
        <div class="section-title" style="color:#F59E0B">Diagnosis</div>
        <div class="section-box">${rx.diagnosis}</div>
      </div>
''');
      }

      // Tests
      if (rx.testsSuggested.isNotEmpty) {
        buf.write('''
      <div class="section">
        <div class="section-title" style="color:#8B5CF6">Tests Ordered</div>
        <div class="section-box"><ul>
''');
        for (final t in rx.testsSuggested) {
          buf.write('          <li>$t</li>\n');
        }
        buf.write('        </ul></div></div>\n');
      }

      // Medicines
      if (rx.medicines.isNotEmpty) {
        buf.write('''
      <div class="section">
        <div class="section-title" style="color:#EF4444">Prescribed Medicines</div>
        <div class="section-box">
          <table><thead><tr>
            <th>Medicine</th><th>Dose</th><th>Frequency</th><th>Duration</th>
          </tr></thead><tbody>
''');
        for (final m in rx.medicines) {
          buf.write('''
            <tr>
              <td>${m.name.isEmpty ? '-' : m.name}</td>
              <td>${m.dose.isEmpty ? '-' : m.dose}</td>
              <td>${m.frequency.isEmpty ? '-' : m.frequency}</td>
              <td>${m.duration.isEmpty ? '-' : m.duration}</td>
            </tr>
''');
        }
        buf.write('          </tbody></table></div></div>\n');
      }

      // Notes
      if (rx.notes != null && rx.notes!.isNotEmpty) {
        buf.write('''
      <div class="section">
        <div class="section-title" style="color:#64748B">Doctor Notes</div>
        <div class="section-box">${rx.notes}</div>
      </div>
''');
      }

      buf.write(
          '      <div class="page-label">Visit ${startVisitNumber + i} of $total</div>\n');
      buf.write('    </div>\n  </div>\n');
    }

    buf.write('''
  <script>
    window.addEventListener('load', function() {
      setTimeout(function() { window.print(); }, 400);
    });
  </script>
</body>
</html>''');
    return buf.toString();
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem(this.label, this.value);
}
