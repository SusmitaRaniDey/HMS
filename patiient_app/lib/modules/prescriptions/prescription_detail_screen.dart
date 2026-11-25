import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../data/models/prescription_model.dart';
import '../../data/providers/booking_provider.dart';
import '../../data/providers/prescription_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  const PrescriptionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments;

    if (argument is PrescriptionModel) {
      return _buildPrescription(context, argument);
    }

    if (argument is int) {
      return FutureBuilder<PrescriptionModel>(
        future: PrescriptionProvider().getPrescriptionById(argument),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              appBar: _PrescriptionAppBar(),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Scaffold(
              appBar: _PrescriptionAppBar(),
              body: Center(child: Text('Could not load prescription')),
            );
          }

          return _buildPrescription(context, snapshot.data!);
        },
      );
    }

    return const Scaffold(
      appBar: _PrescriptionAppBar(),
      body: Center(child: Text('Invalid prescription data')),
    );
  }

  Widget _buildPrescription(BuildContext context, PrescriptionModel rx) {
    final dateStr = rx.createdAt != null
        ? DateFormat('dd MMM yyyy').format(rx.createdAt!)
        : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription'),
        actions: [
          if (rx.hasPdf)
            IconButton(
              icon: Icon(Icons.download_rounded, size: 24.sp),
              tooltip: 'Download PDF',
              onPressed: () => _openPdf(rx),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'HealthGrid',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Dr. ${rx.doctorName}',
                    style: AppTextStyles.h5.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Date: $dateStr',
                    style: AppTextStyles.body2.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Patient info
            _section('Patient', [
              _row('Name', rx.patientName),
              if (rx.patientAge != null) _row('Age', '${rx.patientAge} yrs'),
            ]),

            SizedBox(height: 16.h),

            // Diagnosis
            if (rx.diagnosis != null && rx.diagnosis!.isNotEmpty) ...[
              _section('Diagnosis / Chief Complaint', [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    rx.diagnosis!,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
              SizedBox(height: 16.h),
            ],

            // Medicines
            if (rx.medicines.isNotEmpty) ...[
              _sectionTitle('Prescribed Medicines'),
              SizedBox(height: 10.h),
              ...rx.medicines.map((m) => _medicineCard(m)),
              SizedBox(height: 16.h),
            ],

            // Tests suggested
            if (rx.testsSuggested.isNotEmpty) ...[
              _section(
                'Diagnostic Tests Suggested',
                rx.testsSuggested.map((t) => _bulletRow(t)).toList(),
              ),
              SizedBox(height: 16.h),
            ],

            // Notes
            if (rx.notes != null && rx.notes!.isNotEmpty) ...[
              _section("Doctor's Notes", [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    rx.notes!,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ]),
              SizedBox(height: 16.h),
            ],

            // PDF button
            if (rx.hasPdf) ...[
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openPdf(rx),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('View / Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],

            // Book tests button
            if (rx.testsSuggested.isNotEmpty) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showBookTestsSheet(context, rx),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Book Tests According to Prescription'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),

            Center(
              child: Text(
                'Digitally generated prescription — HealthGrid',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _showBookTestsSheet(BuildContext context, PrescriptionModel rx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookTestsSheet(prescription: rx),
    );
  }

  // Fetches the PDF through the app's authenticated Dio client (so the
  // auth token is attached) instead of launching the URL in an external,
  // unauthenticated browser. The downloaded bytes are then handed to the
  // `printing` package's viewer, which lets the user view/print/share
  // (and thereby save) the file locally.
  Future<void> _openPdf(PrescriptionModel rx) async {
    Helpers.showLoadingDialog(message: 'Loading prescription PDF...');
    try {
      final bytes = await Get.find<ApiService>().downloadBytes(
        '/prescriptions/${rx.id}/download',
      );
      Helpers.hideLoadingDialog();
      await Printing.layoutPdf(
        name: 'prescription_${rx.id}.pdf',
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (e) {
      Helpers.hideLoadingDialog();
      Get.snackbar(
        'Error',
        'Could not load prescription PDF: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: AppTextStyles.subtitle1.copyWith(
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
    ),
  );

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(title),
      SizedBox(height: 10.h),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );

  Widget _row(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            '$label:',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _bulletRow(String text) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Row(
      children: [
        Icon(Icons.fiber_manual_record, size: 8.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Expanded(child: Text(text, style: AppTextStyles.body1)),
      ],
    ),
  );

  Widget _medicineCard(MedicineItem m) => Container(
    margin: EdgeInsets.only(bottom: 10.h),
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.name,
          style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 16.w,
          runSpacing: 4.h,
          children: [
            _chip('Dose', m.dose),
            _chip('Frequency', m.frequency),
            _chip('Duration', m.duration),
          ],
        ),
      ],
    ),
  );

  Widget _chip(String label, String value) => RichText(
    text: TextSpan(
      style: AppTextStyles.caption,
      children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        TextSpan(
          text: value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PrescriptionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _PrescriptionAppBar();

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('Prescription'));

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ── Book Tests Bottom Sheet ───────────────────────────────────────────────────

class _BookTestsSheet extends StatefulWidget {
  const _BookTestsSheet({required this.prescription});
  final PrescriptionModel prescription;

  @override
  State<_BookTestsSheet> createState() => _BookTestsSheetState();
}

class _BookTestsSheetState extends State<_BookTestsSheet> {
  final _provider = BookingProvider();

  bool _isLoading = true;
  bool _isBooking = false;

  // test name → matched diagnostic id (null = not found in catalogue)
  late Map<String, int?> _testIdMap;
  // test name → selected for booking
  late Map<String, bool> _selected;

  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 1));
  String _paymentMethod = 'pay_at_hospital';

  @override
  void initState() {
    super.initState();
    final tests = widget.prescription.testsSuggested;
    _testIdMap = {for (final t in tests) t: null};
    _selected = {for (final t in tests) t: true};
    _fetchDiagnostics();
  }

  Future<void> _fetchDiagnostics() async {
    final all = await _provider.fetchAllDiagnosticsForMatching();
    if (!mounted) return;
    setState(() {
      for (final test in _testIdMap.keys) {
        final match = all.firstWhere(
          (d) =>
              (d['test_name'] ?? '').toString().toLowerCase() ==
              test.toLowerCase(),
          orElse: () => {},
        );
        _testIdMap[test] = match.isEmpty ? null : match['id'] as int?;
      }
      _isLoading = false;
    });
  }

  Future<void> _confirmBooking() async {
    final toBook = _selected.entries
        .where((e) => e.value && _testIdMap[e.key] != null)
        .toList();

    if (toBook.isEmpty) {
      Get.snackbar('Nothing to book',
          'No selected tests were found in the diagnostic catalogue.');
      return;
    }

    setState(() => _isBooking = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_scheduleDate);
    int booked = 0;
    int failed = 0;

    for (final entry in toBook) {
      try {
        await _provider.bookDiagnostic(
          diagnosticId: _testIdMap[entry.key]!,
          scheduleDate: dateStr,
          paymentMethod: _paymentMethod,
          paymentStatus: 'pending',
          isPaid: 'false',
          prescriptionId: widget.prescription.id,
          isPrescribed: true,
          notes: 'Booked from prescription #${widget.prescription.id}',
        );
        booked++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _isBooking = false);
    Navigator.pop(context);

    if (booked > 0) {
      Get.snackbar(
        'Booking Successful',
        '$booked test${booked > 1 ? 's' : ''} booked successfully. '
        'Admin will confirm shortly.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      Get.toNamed(AppRoutes.BOOKINGS);
    }
    if (failed > 0) {
      Get.snackbar('Partial failure', '$failed test(s) could not be booked.',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final matchedCount =
        _testIdMap.values.where((id) => id != null).length;
    final selectedCount = _selected.entries
        .where((e) => e.value && _testIdMap[e.key] != null)
        .length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Icon(Icons.science_outlined,
                      color: AppColors.primary, size: 22.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Book Tests According to Prescription',
                      style: AppTextStyles.subtitle1
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.border),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollCtrl,
                      padding: EdgeInsets.all(20.w),
                      children: [
                        // Tests list
                        Text('Select Tests to Book',
                            style: AppTextStyles.body1
                                .copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 8.h),
                        ...widget.prescription.testsSuggested.map((test) {
                          final found = _testIdMap[test] != null;
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            decoration: BoxDecoration(
                              color: found
                                  ? Colors.white
                                  : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: found
                                    ? AppColors.border
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: _selected[test] ?? false,
                              onChanged: found
                                  ? (v) =>
                                      setState(() => _selected[test] = v!)
                                  : null,
                              title: Text(test,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: found
                                          ? AppColors.textPrimary
                                          : AppColors.textHint)),
                              subtitle: Text(
                                found
                                    ? 'Available in catalogue'
                                    : 'Not found in catalogue — cannot book',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: found
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                              secondary: Icon(
                                found
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                color:
                                    found ? AppColors.success : AppColors.error,
                                size: 20.sp,
                              ),
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        }),

                        if (matchedCount == 0) ...[
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'None of the suggested tests are currently available in the hospital catalogue. Please contact the hospital directly.',
                              style: TextStyle(
                                  fontSize: 13.sp, color: Colors.amber[800]),
                            ),
                          ),
                        ],

                        SizedBox(height: 20.h),

                        // Schedule date
                        Text('Schedule Date',
                            style: AppTextStyles.body1
                                .copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.r),
                              border:
                                  Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    color: AppColors.primary, size: 18.sp),
                                SizedBox(width: 10.w),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_scheduleDate),
                                  style: AppTextStyles.body1.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Icon(Icons.edit_calendar_outlined,
                                    color: AppColors.primary, size: 16.sp),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // Payment method
                        Text('Payment Method',
                            style: AppTextStyles.body1
                                .copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _paymentOption(
                                label: 'Pay at Hospital',
                                icon: Icons.local_hospital_outlined,
                                value: 'pay_at_hospital',
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _paymentOption(
                                label: 'Pay Now',
                                icon: Icons.payment_rounded,
                                value: 'online',
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 28.h),

                        // Confirm button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (selectedCount == 0 || _isBooking)
                                ? null
                                : _confirmBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: _isBooking
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Confirm Booking ($selectedCount test${selectedCount != 1 ? 's' : ''})',
                                    style: AppTextStyles.subtitle1
                                        .copyWith(color: Colors.white),
                                  ),
                          ),
                        ),

                        SizedBox(height: 16.h),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(
      {required String label, required IconData icon, required String value}) {
    final selected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18.sp,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
