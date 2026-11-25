import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_endpoints.dart';
import '../../controller/appointments_controller.dart';
import '../../models/appointment_model.dart';
import '../../routes/admin_routes.dart';
import '../../services/api_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/status_badge.dart';
import 'create_appointment_dialog.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<Uint8List> _generatePdfBytes(List<AppointmentModel> list) async {
    final doc = pw.Document();

    final primaryColor = PdfColor.fromInt(0xFFFF6B35);
    final secondaryColor = PdfColor.fromInt(0xFF1A1F3C);
    final successColor = PdfColor.fromInt(0xFF28C76F);
    final headerBg = PdfColor.fromInt(0xFFF4F5F7);
    final warningColor = PdfColor.fromInt(0xFFFF9F43);
    final errorColor = PdfColor.fromInt(0xFFEA5455);
    final purpleColor = PdfColor.fromInt(0xFF7367F0);

    final countConfirmed = list.where((a) => a.status == 'confirmed').length;
    final countPending = list.where((a) => a.status == 'pending').length;
    final countCompleted = list.where((a) => a.status == 'completed').length;
    final countCancelled = list.where((a) => a.status == 'cancelled').length;
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (context) {
          return [
            // Header Section
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: secondaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
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
                            style: pw.TextStyle(
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
                            'APPOINTMENTS REPORT',
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
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Statistics Section - All in one row matching UI
            pw.Row(
              children: [
                _buildStatBox('Total', list.length.toString(), primaryColor),
                pw.SizedBox(width: 12),
                _buildStatBox('Pending', countPending.toString(), warningColor),
                pw.SizedBox(width: 12),
                _buildStatBox(
                  'Confirmed',
                  countConfirmed.toString(),
                  successColor,
                ),
                pw.SizedBox(width: 12),
                _buildStatBox(
                  'Completed',
                  countCompleted.toString(),
                  purpleColor,
                ),
                pw.SizedBox(width: 12),
                _buildStatBox(
                  'Cancelled',
                  countCancelled.toString(),
                  errorColor,
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Table Section
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
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(0.8),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(0.9),
                  7: const pw.FlexColumnWidth(0.9),
                  8: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: secondaryColor),
                    children: [
                      _buildTableHeaderCell('SL'),
                      _buildTableHeaderCell('ID'),
                      _buildTableHeaderCell('Patient'),
                      _buildTableHeaderCell('Doctor'),
                      _buildTableHeaderCell('Date'),
                      _buildTableHeaderCell('Serial'),
                      _buildTableHeaderCell('Fee'),
                      _buildTableHeaderCell('Status'),
                    ],
                  ),
                  // Data Rows
                  ...list.asMap().entries.map((entry) {
                    final index = entry.key;
                    final a = entry.value;
                    String date = 'N/A';
                    try {
                      if (a.date.isNotEmpty) {
                        date = DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(a.date));
                      }
                    } catch (_) {
                      date = a.date;
                    }

                    final rowColor = index.isEven ? headerBg : PdfColors.white;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowColor),
                      children: [
                        _buildTableCell((index + 1).toString()),
                        _buildTableCell(a.id.toString()),
                        _buildTableCell(a.actualPatientName),
                        _buildTableCell(a.doctorName),
                        _buildTableCell(date),
                        _buildTableCell(a.serialNumber?.toString() ?? 'N/A'),
                        _buildTableCell(
                          'BDT ${a.fee?.toStringAsFixed(0) ?? 'N/A'}',
                        ),
                        _buildTableCellStatus(a.status),
                      ],
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Footer
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFDDDDDD),
                    width: 1,
                  ),
                ),
              ),
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Records: ${list.length}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'HealthGrid © 2026',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
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

  pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    // Create a lighter shade for background (about 85% lighter)
    final lightBg = PdfColor.fromInt(0xFFF5F5F5);

    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: pw.BoxDecoration(
          color: lightBg,
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  pw.Widget _buildTableCellStatus(String status) {
    final statusColor = _getStatusColor(status);
    final lightBg = PdfColor.fromInt(0xFFF5F5F5);

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: pw.BoxDecoration(
          color: lightBg,
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

  PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return PdfColor.fromInt(0xFF28C76F);
      case 'pending':
        return PdfColor.fromInt(0xFFFF9F43);
      case 'cancelled':
        return PdfColor.fromInt(0xFFEA5455);
      case 'completed':
        return PdfColor.fromInt(0xFF7367F0);
      default:
        return PdfColor.fromInt(0xFF999999);
    }
  }

  Future<void> _exportPdf(AppointmentsController controller) async {
    try {
      final bytes = await _generatePdfBytes(controller.filteredAppointments);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'appointments_report.pdf',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate PDF');
    }
  }

  Future<void> _printList(AppointmentsController controller) async {
    try {
      final bytes = await _generatePdfBytes(controller.filteredAppointments);
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      Get.snackbar('Error', 'Failed to print');
    }
  }

  Future<void> _printAppointmentInvoice(int appointmentId) async {
    try {
      final response = await Get.find<ApiService>().dio.get<List<int>>(
        ApiEndpoints.appointmentInvoice(appointmentId),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const <int>[]);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      Helpers.showErrorSnackbar(
        'Invoice error',
        'Could not load the printable invoice',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppointmentsController>();

    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: AdminRoutes.APPOINTMENTS),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(controller),
                  _buildFilterChips(controller),
                  _buildStatistics(controller),
                  _buildAppointmentTypeFilter(controller),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (controller.filteredAppointments.isEmpty) {
                        return _buildEmptyState();
                      }

                      return _buildAppointmentsTable(controller);
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppointmentsController controller) {
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointments Management',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Manage and track all doctor appointments',
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
                    hintText: 'Search appointments...',
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
                  onChanged: controller.searchAppointments,
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
                  onPressed: () => controller.loadAppointments(),
                  icon: Icon(Icons.refresh_rounded, size: 20.sp),
                  tooltip: 'Refresh',
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 8.w),
              // Export PDF
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: () => _exportPdf(controller),
                  icon: Icon(Icons.picture_as_pdf_rounded, size: 20.sp),
                  tooltip: 'Download PDF',
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 8.w),
              // Print
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: () => _printList(controller),
                  icon: Icon(Icons.print_rounded, size: 20.sp),
                  tooltip: 'Print',
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppointmentsController controller) {
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
              child: Wrap(
                spacing: 10.w,
                runSpacing: 8.h,
                children:
                    controller.statusFilters.map((status) {
                      final isSelected =
                          controller.selectedStatus.value == status;
                      return FilterChip(
                        label: Text(_getStatusLabel(status)),
                        selected: isSelected,
                        onSelected: (_) => controller.filterByStatus(status),
                        backgroundColor: Colors.white,
                        selectedColor: _getStatusChipColor(status),
                        labelStyle: TextStyle(
                          fontSize: 12.sp,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? _getStatusChipColor(status)
                              : AppColors.border,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      );
                    }).toList()..addAll(
                      ['online', 'offline'].map((type) {
                        final isSelected =
                            controller.selectedAppointmentType.value == type;
                        final color = type == 'online'
                            ? Colors.blue
                            : AppColors.primary;
                        return FilterChip(
                          avatar: Icon(
                            type == 'online'
                                ? Icons.videocam_rounded
                                : Icons.local_hospital_rounded,
                            size: 16.sp,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          label: Text(type == 'online' ? 'Online' : 'Offline'),
                          selected: isSelected,
                          onSelected: (_) =>
                              controller.filterByAppointmentType(type),
                          backgroundColor: Colors.white,
                          selectedColor: color,
                          labelStyle: TextStyle(
                            fontSize: 12.sp,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected ? color : AppColors.border,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        );
                      }),
                    ),
              ),
            ),
            SizedBox(width: 12.w),
            // Date range filter on the right side of filters
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

  Widget _buildStatistics(AppointmentsController controller) {
    return Container(
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
      child: Obx(
        () => Row(
          children: [
            _buildStatCard(
              'Total',
              controller.totalAppointments,
              AppColors.primary,
              Icons.calendar_today_rounded,
            ),
            _buildStatCard(
              'Pending',
              controller.pendingCount,
              AppColors.pending,
              Icons.schedule_rounded,
            ),
            _buildStatCard(
              'Confirmed',
              controller.confirmedCount,
              AppColors.confirmed,
              Icons.check_circle_rounded,
            ),
            _buildStatCard(
              'Completed',
              controller.completedCount,
              AppColors.completed,
              Icons.task_alt_rounded,
            ),
            _buildStatCard(
              'Cancelled',
              controller.cancelledCount,
              AppColors.cancelled,
              Icons.cancel_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.w),
        margin: EdgeInsets.symmetric(horizontal: 6.w),
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
              count.toString(),
              style: TextStyle(
                fontSize: 22.sp,
                color: color,
                fontWeight: FontWeight.bold,
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

  Widget _buildAppointmentTypeFilter(AppointmentsController controller) {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const CreateAppointmentDialog(),
              );
              if (created == true) await controller.loadAppointments();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTable(AppointmentsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = constraints.maxWidth - 48.w;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: tableMinWidth),
                child: DataTable(
                  columnSpacing: 12.w,
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.background,
                  ),
                  headingTextStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                  columns: [
                    DataColumn(
                      label: _headerCell('SL', center: true),
                      numeric: true,
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('#ID', center: true),
                      numeric: true,
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Patient', center: true),
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Doctor', center: true),
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Date', center: true),
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Serial', center: true),
                      numeric: true,
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Fee', center: true),
                      numeric: true,
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Payment Status', center: true),
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Status', center: true),
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                    DataColumn(
                      label: _headerCell('Actions', center: true),
                      headingRowAlignment: MainAxisAlignment.center,
                    ),
                  ],
                  rows: controller.filteredAppointments.asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final appointment = entry.value;
                    String formattedDate = 'N/A';
                    try {
                      if (appointment.date.isNotEmpty) {
                        final date = DateTime.parse(appointment.date);
                        formattedDate = DateFormat('dd MMM yyyy').format(date);
                      }
                    } catch (e) {
                      formattedDate = appointment.date;
                    }
                    final formattedSlot = _formatAppointmentSlot(
                      appointment.startTime,
                    );
                    return DataRow(
                      cells: [
                        DataCell(
                          Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              '#${appointment.id}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180.w,
                            child: Row(
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      appointment.actualPatientName.isNotEmpty
                                          ? appointment.actualPatientName[0]
                                                .toUpperCase()
                                          : 'P',
                                      style: TextStyle(
                                        color: AppColors.info,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        appointment.actualPatientName,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        appointment.actualPatientContact,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (appointment.appointmentFor ==
                                              'other' &&
                                          appointment.otherPatientAge != null)
                                        Text(
                                          'Age: ${appointment.otherPatientAge}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 170.w,
                            child: Row(
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.medical_services_rounded,
                                      color: AppColors.secondary,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        appointment.doctorName,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        appointment.doctorSpecialty,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16.sp,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 6.w),
                                Text('$formattedDate  •  $formattedSlot'),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                appointment.serialNumber != null
                                    ? '#${appointment.serialNumber}'
                                    : 'N/A',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              appointment.fee != null
                                  ? '৳${appointment.fee!.toStringAsFixed(0)}'
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: appointment.isPaidStatus
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: appointment.isPaidStatus
                                      ? AppColors.success.withValues(alpha: 0.4)
                                      : Colors.orange.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                appointment.isPaidDisplay,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: appointment.isPaidStatus
                                      ? AppColors.success
                                      : Colors.orange[800],
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: StatusBadge(status: appointment.status),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.visibility_rounded,
                                      color: AppColors.primary,
                                      size: 20.sp,
                                    ),
                                    onPressed: () => _showAppointmentDetails(
                                      context,
                                      appointment,
                                    ),
                                    tooltip: 'View Details',
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20.sp,
                                  ),
                                  tooltip: 'Actions',
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  onSelected: (value) => _handleAction(
                                    controller,
                                    value,
                                    appointment.id,
                                    appointment.status,
                                  ),
                                  itemBuilder: (context) =>
                                      _buildActionMenuItems(appointment.status),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete_rounded,
                                      color: AppColors.error,
                                      size: 18.sp,
                                    ),
                                    onPressed: () => controller
                                        .deleteAppointment(appointment.id),
                                    tooltip: 'Delete',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerCell(String text, {bool center = false}) {
    return Center(
      child: Text(
        text,
        maxLines: 2,
        textAlign: center ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.visible,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildActionMenuItems(String currentStatus) {
    final items = <PopupMenuEntry<String>>[];

    // Show status options based on current status
    if (currentStatus == 'pending') {
      // Show all remaining statuses
      items.addAll([
        const PopupMenuItem(value: 'confirmed', child: Text('✅ Confirm')),
        const PopupMenuItem(value: 'completed', child: Text('✔️ Complete')),
        const PopupMenuItem(value: 'cancelled', child: Text('🚫 Cancel')),
      ]);
    } else if (currentStatus == 'confirmed') {
      // Show remaining statuses without pending
      items.addAll([
        const PopupMenuItem(value: 'completed', child: Text('✔️ Complete')),
        const PopupMenuItem(value: 'cancelled', child: Text('🚫 Cancel')),
      ]);
    } else if (currentStatus == 'cancelled') {
      // Show nothing - no status changes allowed
    } else if (currentStatus == 'completed') {
      items.add(
        const PopupMenuItem(value: 'view', child: Text('👁️ View Only')),
      );
    }

    return items;
  }

  void _handleAction(
    AppointmentsController controller,
    String action,
    int appointmentId,
    String currentStatus,
  ) {
    if (action == 'view') {
      Get.snackbar('Info', 'Appointment is already completed');
      return;
    }

    if (action == 'cancelled') {
      _showCancelDialog(controller, appointmentId);
    } else {
      controller.updateAppointmentStatus(appointmentId, action);
    }
  }

  void _showCancelDialog(AppointmentsController controller, int appointmentId) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a cancellation reason:'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.cancelAppointment(
                  appointmentId,
                  reasonController.text.trim(),
                );
                reasonController.dispose();
                Get.back();
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(
    BuildContext context,
    AppointmentsController controller,
    AppointmentModel appointment,
  ) {
    DateTime selectedDate =
        DateTime.tryParse(appointment.date) ?? DateTime.now();
    int selectedDoctorId = appointment.doctorId;
    String? selectedSlot;
    final reasonController = TextEditingController();
    List<Map<String, dynamic>> doctors = [];
    List<Map<String, dynamic>> slots = [];
    bool loadingDoctors = true;
    bool loadingSlots = true;

    Future<void> loadSlots(StateSetter setState) async {
      setState(() {
        loadingSlots = true;
        selectedSlot = null;
      });
      try {
        final value = await controller.loadDoctorTimeSlots(
          selectedDoctorId,
          DateFormat('yyyy-MM-dd').format(selectedDate),
          appointment.type,
        );
        setState(() => slots = value);
      } catch (_) {
        setState(() => slots = []);
      } finally {
        setState(() => loadingSlots = false);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingDoctors) {
            loadingDoctors = false;
            controller
                .loadRescheduleDoctors()
                .then((value) {
                  if (!context.mounted) return;
                  setDialogState(() => doctors = value);
                  loadSlots(setDialogState);
                })
                .catchError((_) {
                  if (context.mounted) {
                    setDialogState(() => loadingSlots = false);
                  }
                });
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.edit_calendar_rounded,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                const Text('Reschedule Appointment'),
              ],
            ),
            content: SizedBox(
              width: 650.w,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment #${appointment.id} — ${appointment.actualPatientName}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    DropdownButtonFormField<int>(
                      initialValue:
                          doctors.any((d) => d['id'] == selectedDoctorId)
                          ? selectedDoctorId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'New Doctor',
                        border: OutlineInputBorder(),
                      ),
                      items: doctors
                          .map(
                            (doctor) => DropdownMenuItem<int>(
                              value: doctor['id'] as int,
                              child: Text(
                                '${doctor['name']} — ${doctor['specialty'] ?? 'General'}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        selectedDoctorId = value;
                        loadSlots(setDialogState);
                      },
                    ),
                    SizedBox(height: 14.h),

                    // Date picker row
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          loadSlots(setDialogState);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    Text(
                      'Time Slot',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (loadingSlots)
                      const Center(child: CircularProgressIndicator())
                    else if (slots.isEmpty)
                      const Text(
                        'The selected doctor has no schedule on this date.',
                      )
                    else
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: slots.map((slot) {
                          final start = slot['startTime'] as String;
                          final end = slot['endTime'] as String;
                          final booked = slot['isBooked'] == true;
                          final selected = selectedSlot == start;
                          final color = booked ? Colors.red : Colors.green;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: booked
                                ? null
                                : (_) => setDialogState(
                                    () => selectedSlot = start,
                                  ),
                            label: Text(
                              '$start–$end  ${booked ? 'Booked' : 'Available'}',
                            ),
                            avatar: Icon(
                              booked ? Icons.close : Icons.check,
                              size: 16,
                              color: color,
                            ),
                            disabledColor: Colors.red.withValues(alpha: .12),
                            selectedColor: Colors.green.withValues(alpha: .28),
                            backgroundColor: Colors.green.withValues(
                              alpha: .10,
                            ),
                            side: BorderSide(
                              color: color.withValues(alpha: .55),
                            ),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: 14.h),
                    TextField(
                      controller: reasonController,
                      maxLength: 500,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason for change (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                  if (selectedSlot == null) return;
                  final success = await controller.rescheduleAppointment(
                    appointment.id,
                    newDate: newDate,
                    doctorId: selectedDoctorId,
                    timeSlot: selectedSlot!,
                    reason: reasonController.text,
                  );
                  if (success && context.mounted) {
                    reasonController.dispose();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80.sp,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16.h),
          Text('No appointments found', style: AppTextStyles.h4),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed'; // ✅ Changed from 'Approved'
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusChipColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.pending;
      case 'confirmed':
        return AppColors.confirmed;
      case 'completed':
        return AppColors.completed;
      case 'cancelled':
        return AppColors.cancelled;
      default:
        return AppColors.primary;
    }
  }

  void _showAppointmentDetails(
    BuildContext context,
    AppointmentModel appointment,
  ) {
    final dateFormatter = DateFormat('MMM dd, yyyy');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
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
                      'Appointment Details',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Status + Type badges
                Row(
                  children: [
                    Text('Status: ', style: AppTextStyles.subtitle1),
                    StatusBadge(status: appointment.status),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: appointment.isOnline
                            ? Colors.blue.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: appointment.isOnline
                              ? Colors.blue.withValues(alpha: 0.4)
                              : Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            appointment.isOnline
                                ? Icons.videocam_rounded
                                : Icons.local_hospital_rounded,
                            size: 14.sp,
                            color: appointment.isOnline
                                ? Colors.blue
                                : Colors.grey[700],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            appointment.isOnline ? 'Online' : 'In-Person',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: appointment.isOnline
                                  ? Colors.blue
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Patient Information
                _buildSectionTitle('Patient Information'),
                SizedBox(height: 8.h),
                _buildDetailRow('Name', appointment.actualPatientName),
                _buildDetailRow('Contact', appointment.actualPatientContact),

                SizedBox(height: 16.h),

                // Doctor Information
                _buildSectionTitle('Doctor Information'),
                SizedBox(height: 8.h),
                _buildDetailRow('Name', appointment.doctorName),
                _buildDetailRow('Specialty', appointment.doctorSpecialty),

                SizedBox(height: 16.h),

                // Appointment Information
                _buildSectionTitle('Appointment Information'),
                SizedBox(height: 8.h),
                _buildDetailRow(
                  'Date',
                  dateFormatter.format(DateTime.parse(appointment.date)),
                ),
                _buildDetailRow(
                  'Serial Number',
                  appointment.serialNumber != null
                      ? '#${appointment.serialNumber}'
                      : 'N/A',
                ),
                _buildDetailRow(
                  'Fee',
                  appointment.fee != null
                      ? '৳${appointment.fee!.toStringAsFixed(0)}'
                      : 'N/A',
                ),
                _buildDetailRow('Payment', appointment.isPaidDisplay),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: () => _printAppointmentInvoice(appointment.id),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print invoice'),
                ),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _appointmentRefund(appointment.id),
                  builder: (context, snapshot) {
                    final refund = snapshot.data;
                    final isRefunded = refund?['refundStatus'] == 'refunded';
                    if (refund == null && !appointment.isPaidStatus) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (refund != null) ...[
                          _buildDetailRow(
                            'Refund',
                            (refund['refundStatus'] as String? ?? 'pending')
                                .toUpperCase(),
                          ),
                          if (isRefunded)
                            _buildDetailRow('Updated Payment', 'Unpaid'),
                        ],
                        if (refund == null && appointment.isPaidStatus) ...[
                          SizedBox(height: 12.h),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showAdminInitiateRefund(context, appointment),
                            icon: Icon(
                              Icons.assignment_return_rounded,
                              size: 18.sp,
                            ),
                            label: const Text('Initiate Refund'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                if (appointment.cancellationReason != null) ...[
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Cancellation Information'),
                  SizedBox(height: 8.h),
                  _buildDetailRow('Reason', appointment.cancellationReason!),
                ],

                // ── Zoom Meeting Info (online appointments only) ──
                if (appointment.isOnline) ...[
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Zoom Meeting'),
                  SizedBox(height: 8.h),
                  if (appointment.hasMeeting) ...[
                    _buildDetailRow(
                      'Meeting Status',
                      (appointment.meetingStatus ?? 'scheduled').toUpperCase(),
                    ),
                    if (appointment.zoomPassword != null &&
                        appointment.zoomPassword!.isNotEmpty)
                      _buildDetailRow('Password', appointment.zoomPassword!),
                    SizedBox(height: 12.h),
                    // Patient join link (read-only copy)
                    _buildLinkRow(
                      label: 'Patient Join URL',
                      url: appointment.zoomJoinUrl!,
                    ),
                    SizedBox(height: 8.h),
                    // Host start button
                    if (appointment.zoomStartUrl != null &&
                        appointment.zoomStartUrl!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _launchUrl(appointment.zoomStartUrl!),
                          icon: Icon(Icons.videocam_rounded, size: 18.sp),
                          label: const Text('Start Meeting as Host'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D8CFF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                      ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Zoom meeting will be created automatically when you confirm this appointment.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.amber[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                SizedBox(height: 24.h),

                _buildDetailRow('Current Slot', appointment.timeSlot ?? 'N/A'),

                SizedBox(height: 16.h),

                // Reschedule Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRescheduleDialog(
                        context,
                        Get.find<AppointmentsController>(),
                        appointment,
                      );
                    },
                    icon: Icon(Icons.edit_calendar_rounded, size: 18.sp),
                    label: const Text('Reschedule Appointment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // Close Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open link');
    }
  }

  Future<Map<String, dynamic>?> _appointmentRefund(int appointmentId) async {
    try {
      final apiService = Get.find<ApiService>();
      final response = await apiService.get(ApiEndpoints.ADMIN_REFUNDS);
      final refunds = response.data as List;
      for (final item in refunds) {
        final map = item as Map<String, dynamic>;
        if (map['appointmentId'] == appointmentId) return map;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _showAdminInitiateRefund(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    const reasons = {
      'patient_cancelled': 'Patient cancelled',
      'doctor_no_show': "Doctor didn't join",
      'no_consultation': 'No consultation happened',
    };
    var selectedReason = reasons.keys.first;
    final noteController = TextEditingController();
    final accountController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    items: reasons.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedReason = value);
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Optional note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(
                      labelText: 'Refund account',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (accountController.text.trim().isEmpty) {
                          Helpers.showErrorSnackbar(
                            'Error',
                            'Enter refund account number',
                          );
                          return;
                        }
                        try {
                          final apiService = Get.find<ApiService>();
                          await apiService.post(
                            ApiEndpoints.adminRefundInitiate(appointment.id),
                            data: {
                              'reason': selectedReason,
                              if (noteController.text.trim().isNotEmpty)
                                'patientNote': noteController.text.trim(),
                              'refundToAccount': accountController.text.trim(),
                            },
                          );
                          if (context.mounted) Navigator.pop(context);
                          Helpers.showSuccessSnackbar(
                            'Success',
                            'Refund initiated',
                          );
                        } on DioException catch (e) {
                          Helpers.showErrorSnackbar(
                            'Error',
                            e.response?.data['message'] ??
                                'Failed to initiate refund',
                          );
                        }
                      },
                      child: const Text('Initiate Refund'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLinkRow({required String label, required String url}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150.w,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    url,
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, size: 16.sp),
                  tooltip: 'Copy link',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    Get.snackbar(
                      'Copied',
                      'Link copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.subtitle1.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  String _formatAppointmentSlot(String? startTime) {
    if (startTime == null || startTime.trim().isEmpty) return 'N/A';

    final value = startTime.trim();
    final parsedDateTime = DateTime.tryParse(value);
    if (parsedDateTime != null) {
      return DateFormat('hh:mm a').format(parsedDateTime.toLocal());
    }

    final timeParts = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (timeParts != null) {
      final hour = int.tryParse(timeParts.group(1)!);
      final minute = int.tryParse(timeParts.group(2)!);
      if (hour != null && minute != null && hour < 24 && minute < 60) {
        return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hour, minute));
      }
    }

    return value;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150.w,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body2)),
        ],
      ),
    );
  }
}
