import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';

import '../../config/api_endpoints.dart';
import '../../controller/diagnostic_booking_controller.dart';
import '../../models/diagnostic_booking_model.dart';
import '../../routes/admin_routes.dart';
import '../../services/api_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/status_badge.dart';

class DiagnosticBookingsListScreen extends StatefulWidget {
  const DiagnosticBookingsListScreen({super.key});

  @override
  State<DiagnosticBookingsListScreen> createState() =>
      _DiagnosticBookingsListScreenState();
}

class _DiagnosticBookingsListScreenState
    extends State<DiagnosticBookingsListScreen> {
  //final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    //_scrollController.dispose();
    super.dispose();
  }

  Future<Uint8List> _generatePdfBytes(List<DiagnosticBookingModel> list) async {
    final doc = pw.Document();

    final primaryColor = PdfColor.fromInt(0xFFFF6B35);
    final secondaryColor = PdfColor.fromInt(0xFF1A1F3C);
    final successColor = PdfColor.fromInt(0xFF28C76F);
    final headerBg = PdfColor.fromInt(0xFFF4F5F7);
    final warningColor = PdfColor.fromInt(0xFFFF9F43);
    final errorColor = PdfColor.fromInt(0xFFEA5455);
    final infoColor = PdfColor.fromInt(0xFF00CFE8);

    final countPending = list.where((b) => b.status == 'pending').length;
    final countConfirmed = list.where((b) => b.status == 'confirmed').length;
    final countCompleted = list.where((b) => b.status == 'completed').length;
    final countCancelled = list.where((b) => b.status == 'cancelled').length;
    final paidCount = list.where((b) => b.isPaid == 'paid').length;
    final totalPaid = list.fold<double>(0, (sum, b) {
      return sum + (double.tryParse(b.paidAmount ?? '') ?? 0);
    });

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: secondaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'HealthGrid',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Hospital Management System',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DIAGNOSTIC BOOKINGS REPORT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${DateFormat('dd MMM yyyy | HH:mm').format(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromInt(0xFFCCCCCC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                _buildPdfStatBox('Total', list.length.toString(), primaryColor),
                pw.SizedBox(width: 10),
                _buildPdfStatBox(
                  'Pending',
                  countPending.toString(),
                  warningColor,
                ),
                pw.SizedBox(width: 10),
                _buildPdfStatBox(
                  'Confirmed',
                  countConfirmed.toString(),
                  successColor,
                ),
                pw.SizedBox(width: 10),
                _buildPdfStatBox(
                  'Completed',
                  countCompleted.toString(),
                  infoColor,
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                _buildPdfStatBox(
                  'Cancelled',
                  countCancelled.toString(),
                  errorColor,
                ),
                pw.SizedBox(width: 10),
                _buildPdfStatBox('Paid', paidCount.toString(), successColor),
                pw.SizedBox(width: 10),
                _buildPdfStatBox(
                  'Paid Amount',
                  'BDT ${totalPaid.toStringAsFixed(0)}',
                  successColor,
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFFDDDDDD)),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromInt(0xFFEEEEEE),
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.7),
                  1: const pw.FlexColumnWidth(1.35),
                  2: const pw.FlexColumnWidth(1.8),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.15),
                  5: const pw.FlexColumnWidth(0.9),
                  6: const pw.FlexColumnWidth(0.95),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: secondaryColor),
                    children: [
                      _buildPdfTableHeaderCell('ID'),
                      _buildPdfTableHeaderCell('Patient'),
                      _buildPdfTableHeaderCell('Test'),
                      _buildPdfTableHeaderCell('Category'),
                      _buildPdfTableHeaderCell('Date'),
                      _buildPdfTableHeaderCell('Payment'),
                      _buildPdfTableHeaderCell('Status'),
                    ],
                  ),
                  ...list.asMap().entries.map((entry) {
                    final index = entry.key;
                    final booking = entry.value;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index.isEven ? headerBg : PdfColors.white,
                      ),
                      children: [
                        _buildPdfTableCell('#${booking.id}'),
                        _buildPdfTableCell(booking.patientName),
                        _buildPdfTableCell(booking.diagnosticName),
                        _buildPdfTableCell(booking.diagnosticCategory),
                        _buildPdfTableCell(
                          _formatPdfDate(booking.scheduleDate),
                        ),
                        _buildPdfTableCell(
                          booking.isPaid == 'paid' ? 'Paid' : 'Unpaid',
                        ),
                        _buildPdfTableCellStatus(booking.status),
                      ],
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFDDDDDD),
                    width: 1,
                  ),
                ),
              ),
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Records: ${list.length}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.Text(
                    'HealthGrid 2026',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPdfStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF5F5F5),
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text.isNotEmpty ? text : 'N/A',
        style: const pw.TextStyle(fontSize: 9),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  pw.Widget _buildPdfTableCellStatus(String status) {
    final statusColor = _getPdfStatusColor(status);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF5F5F5),
          borderRadius: pw.BorderRadius.circular(3),
          border: pw.Border.all(color: statusColor, width: 0.5),
        ),
        child: pw.Text(
          status.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
            color: statusColor,
          ),
        ),
      ),
    );
  }

  PdfColor _getPdfStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return PdfColor.fromInt(0xFF28C76F);
      case 'pending':
        return PdfColor.fromInt(0xFFFF9F43);
      case 'cancelled':
      case 'rejected':
        return PdfColor.fromInt(0xFFEA5455);
      case 'completed':
        return PdfColor.fromInt(0xFF7367F0);
      default:
        return PdfColor.fromInt(0xFF999999);
    }
  }

  String _formatPdfDate(String value) {
    try {
      if (value.isNotEmpty) {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(value));
      }
    } catch (_) {}
    return value.isNotEmpty ? value : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DiagnosticBookingsController>();

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(selectedRoute: AdminRoutes.DIAGNOSTIC_BOOKINGS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(controller),
                _buildStatsBar(controller),
                _buildFilterBar(controller),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.filteredBookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 80.sp,
                              color: AppColors.textHint,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No diagnostic bookings found',
                              style: AppTextStyles.h4,
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildBookingsTable(controller);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(DiagnosticBookingsController controller) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: AppColors.warningGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.science_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diagnostic Bookings',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Manage all diagnostic test bookings',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 280.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by patient, test...',
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onChanged: controller.searchBookings,
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: () => controller.loadBookings(),
                  icon: Icon(Icons.refresh_rounded, size: 20.sp),
                  tooltip: 'Refresh',
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: () => _exportPdf(controller),
                  icon: Icon(Icons.picture_as_pdf, size: 20.sp),
                  tooltip: 'Download PDF',
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: () => _printList(controller),
                  icon: Icon(Icons.print, size: 20.sp),
                  tooltip: 'Print',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(DiagnosticBookingsController controller) async {
    try {
      final bytes = await _generatePdfBytes(controller.filteredBookings);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'diagnostic_bookings_report.pdf',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate PDF');
    }
  }

  Future<void> _printList(DiagnosticBookingsController controller) async {
    try {
      final bytes = await _generatePdfBytes(controller.filteredBookings);
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      Get.snackbar('Error', 'Failed to print');
    }
  }

  Future<void> _printBookingInvoice(int bookingId) async {
    try {
      final response = await Get.find<ApiService>().dio.get<List<int>>(
        ApiEndpoints.diagnosticBookingInvoice(bookingId),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const <int>[]);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      Get.snackbar('Invoice error', 'Could not load the printable invoice');
    }
  }

  Widget _buildStatsBar(DiagnosticBookingsController controller) {
    return Obx(
      () => Container(
        margin: EdgeInsets.all(24.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem(
              'Total',
              controller.totalBookings.toString(),
              AppColors.info,
              Icons.list_alt_rounded,
            ),
            SizedBox(width: 16.w),
            _buildStatItem(
              'Pending',
              controller.pendingCount.toString(),
              AppColors.pending,
              Icons.schedule_rounded,
            ),
            SizedBox(width: 16.w),
            _buildStatItem(
              'Confirmed',
              controller.confirmedCount.toString(),
              AppColors.confirmed,
              Icons.check_circle_rounded,
            ),
            SizedBox(width: 16.w),
            _buildStatItem(
              'Completed',
              controller.completedCount.toString(),
              AppColors.completed,
              Icons.task_alt_rounded,
            ),
            SizedBox(width: 16.w),
            _buildStatItem(
              'Cancelled',
              controller.cancelledCount.toString(),
              AppColors.cancelled,
              Icons.cancel_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(DiagnosticBookingsController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Filter by Status:',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  _buildFilterChip(controller, 'All', 'all'),
                  SizedBox(width: 10.w),
                  _buildFilterChip(controller, 'Pending', 'pending'),
                  SizedBox(width: 10.w),
                  _buildFilterChip(controller, 'Confirmed', 'confirmed'),
                  SizedBox(width: 10.w),
                  _buildFilterChip(controller, 'Completed', 'completed'),
                  SizedBox(width: 10.w),
                  _buildFilterChip(controller, 'Cancelled', 'cancelled'),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 3650),
                  ),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  initialDateRange:
                      controller.selectedStartDate.value != null &&
                          controller.selectedEndDate.value != null
                      ? DateTimeRange(
                          start: controller.selectedStartDate.value!,
                          end: controller.selectedEndDate.value!,
                        )
                      : null,
                );
                if (picked != null) {
                  controller.filterByDateRange(picked);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      controller.selectedStartDate.value != null &&
                              controller.selectedEndDate.value != null
                          ? '${DateFormat('dd MMM yyyy').format(controller.selectedStartDate.value!)} - ${DateFormat('dd MMM yyyy').format(controller.selectedEndDate.value!)}'
                          : 'All Dates',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (controller.selectedStartDate.value != null &&
                        controller.selectedEndDate.value != null) ...[
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () => controller.filterByDateRange(null),
                        child: Icon(
                          Icons.close,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    DiagnosticBookingsController controller,
    String label,
    String value,
  ) {
    final isSelected = controller.selectedStatus.value == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => controller.filterByStatus(value),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      labelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildBookingsTable(DiagnosticBookingsController controller) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            headingTextStyle: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            dataTextStyle: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
            ),
            columns: [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Patient')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Test Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Schedule Date')),
              DataColumn(label: Text('Rx')),
              DataColumn(label: Text('Payment')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: controller.filteredBookings.map((booking) {
              final date = DateTime.parse(booking.scheduleDate);
              final formattedDate = DateFormat('dd MMM yyyy').format(date);

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#${booking.id}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              booking.patientName.isNotEmpty
                                  ? booking.patientName[0].toUpperCase()
                                  : 'P',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        SizedBox(
                          width: 100.w,
                          child: Text(
                            booking.patientName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      booking.patientPhone.isNotEmpty
                          ? booking.patientPhone
                          : 'N/A',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180.w,
                      child: Text(
                        booking.diagnosticName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        booking.diagnosticCategory,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(formattedDate, style: TextStyle(fontSize: 16.sp)),
                      ],
                    ),
                  ),
                  DataCell(
                    booking.isPrescribed
                        ? Tooltip(
                            message: 'Prescription attached',
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 13.sp,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Rx',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Tooltip(
                            message: 'No prescription',
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 13.sp,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'No Rx',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  DataCell(
                    StatusBadge(
                      status: booking.isPaid == 'paid' ? 'paid' : 'unpaid',
                      showIcon: true,
                    ),
                  ),
                  DataCell(StatusBadge(status: booking.status)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: AppColors.info,
                          ),
                          onPressed: () => _showBookingDetails(booking),
                          tooltip: 'View Details',
                        ),
                        if (booking.status == 'pending') ...[
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up_rounded,
                              color: AppColors.success,
                              size: 20.sp,
                            ),
                            onPressed: () =>
                                controller.approveBooking(booking.id),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.thumb_down_rounded,
                              color: AppColors.error,
                              size: 20.sp,
                            ),
                            onPressed: () =>
                                _showRejectDialog(controller, booking.id),
                            tooltip: 'Reject',
                          ),
                        ],
                        if (booking.status == 'confirmed')
                          IconButton(
                            icon: const Icon(
                              Icons.done_all,
                              color: AppColors.success,
                            ),
                            onPressed: () => controller.updateBookingStatus(
                              booking.id,
                              'completed',
                            ),
                            tooltip: 'Mark Completed',
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.error,
                          ),
                          onPressed: () => controller.deleteBooking(booking.id),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(booking) {
    final date = DateTime.parse(booking.scheduleDate);
    final formattedDate = DateFormat('EEEE, dd MMM yyyy').format(date);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 600.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking Details',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              _buildDetailSection('Patient Information', [
                _buildDetailRow('Name', booking.patientName),
                _buildDetailRow(
                  'Phone',
                  booking.patientPhone.isNotEmpty
                      ? booking.patientPhone
                      : 'N/A',
                ),
              ]),

              SizedBox(height: 20.h),

              _buildDetailSection('Test Information', [
                _buildDetailRow('Test Name', booking.diagnosticName),
                _buildDetailRow('Category', booking.diagnosticCategory),
                _buildDetailRow(
                  'Prescription',
                  booking.isPrescribed ? '✅ Attached' : '⚠️ Not provided',
                ),
              ]),

              SizedBox(height: 20.h),

              _buildDetailSection('Booking Details', [
                _buildDetailRow('Schedule Date', formattedDate),
                _buildDetailRow(
                  'Created',
                  DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt),
                ),
                _buildDetailRow('Status', ''),
              ]),

              Padding(
                padding: EdgeInsets.only(left: 16.w, top: 8.h),
                child: StatusBadge(status: booking.status, fontSize: 13.sp),
              ),

              if (booking.paymentMethod != null ||
                  booking.paidAmount != null) ...[
                SizedBox(height: 20.h),
                _buildDetailSection('Payment Information', [
                  if (booking.paymentMethod != null)
                    _buildDetailRow(
                      'Payment Method',
                      booking.paymentMethod == 'pay_now'
                          ? 'Pay Now'
                          : 'Pay in Hospital',
                    ),
                  if (booking.paymentStatus != null)
                    _buildDetailRow(
                      'Payment Status',
                      booking.paymentStatus!.toUpperCase(),
                    ),
                  if (booking.isPaid != null)
                    _buildDetailRow(
                      'Payment',
                      booking.isPaid == 'paid' ? '✅ Paid' : '❌ Unpaid',
                    ),
                  if (booking.paidAmount != null)
                    _buildDetailRow('Amount', '৳${booking.paidAmount}'),
                  if (booking.transactionId != null)
                    _buildDetailRow('Transaction ID', booking.transactionId!),
                  if (booking.bankTransactionId != null)
                    _buildDetailRow(
                      'Bank Transaction ID',
                      booking.bankTransactionId!,
                    ),
                ]),
              ],

              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: () => _printBookingInvoice(booking.id),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print invoice'),
              ),

              if (booking.notes != null) ...[
                SizedBox(height: 20.h),
                _buildDetailSection('Notes', [
                  Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Text(booking.notes!, style: AppTextStyles.body2),
                  ),
                ]),
              ],

              if (booking.cancellationReason != null) ...[
                SizedBox(height: 20.h),
                _buildDetailSection('Cancellation Reason', [
                  Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Text(
                      booking.cancellationReason!,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ]),
              ],

              if (booking.adminNote != null &&
                  booking.adminNote!.isNotEmpty) ...[
                SizedBox(height: 20.h),
                _buildDetailSection('Admin Note', [
                  Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Text(
                      booking.adminNote!,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(
    DiagnosticBookingsController controller,
    int bookingId,
  ) {
    final reasonController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject Booking',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                'Provide a reason for rejection (optional):',
                style: AppTextStyles.body2,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      reasonController.dispose();
                      Get.back();
                    },
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: () {
                      controller.rejectBooking(
                        bookingId,
                        reason: reasonController.text.trim(),
                      );
                      reasonController.dispose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Confirm Reject'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 12.h),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150.w,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
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
  }
}
