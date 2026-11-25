import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:patient_app/data/models/patient_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../modules/auth/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'appointments_controller.dart';
import '../../data/providers/appointment_provider.dart';

class AppointmentsScreen extends GetView<AppointmentsController> {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: controller.filters.length,
              itemBuilder: (context, index) {
                final filter = controller.filters[index];
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Obx(() {
                    final isSelected =
                        controller.selectedFilter.value == filter;
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => controller.applyFilter(filter),
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Appointments List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const LoadingWidget(message: 'Loading appointments...');
              }

              if (controller.filteredAppointments.isEmpty) {
                return EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No Appointments',
                  message: controller.selectedFilter.value == 'All'
                      ? 'You haven\'t booked any appointments yet'
                      : 'No ${controller.selectedFilter.value.toLowerCase()} appointments',
                  buttonText: 'Book Appointment',
                  onButtonPressed: () => Get.offAllNamed(AppRoutes.DOCTORS),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshAppointments,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: controller.filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = controller.filteredAppointments[index];
                    return _buildAppointmentCard(appointment, context);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Future<void> _joinMeeting(int appointmentId) async {
    try {
      final url = await AppointmentProvider().getMeetingJoinUrl(appointmentId);
      controller.loadAppointments();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Helpers.showErrorSnackbar('Error', 'Could not open Zoom meeting');
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Meeting unavailable', e.toString());
    }
  }

  Widget _buildAppointmentCard(appointment, BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.APPOINTMENT_DETAIL, arguments: appointment),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Doctor Avatar
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 28.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12.w),

                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctor?.name ?? 'Doctor',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        appointment.doctor?.specialty ?? 'Specialty',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Status Badge
                StatusBadge(status: appointment.status),
              ],
            ),

            SizedBox(height: 12.h),

            Divider(color: AppColors.divider),

            SizedBox(height: 12.h),

            // Date and Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  Helpers.formatDate(appointment.date),
                  style: AppTextStyles.body2,
                ),
                SizedBox(width: 16.w),
                Icon(Icons.queue, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 8.w),
                Text(
                  'Serial Number #${appointment.serialNumber}',
                  style: AppTextStyles.body2,
                ),
              ],
            ),

            // Join Meeting button (online appointments, time-gated)
            if (appointment.canJoinMeeting) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinMeeting(appointment.id as int),
                  icon: Icon(Icons.videocam_rounded, size: 18.sp),
                  label: const Text('Join Meeting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
            ],

            // View Prescription button
            if (appointment.prescriptionId != null) ...[
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.PRESCRIPTION_DETAIL,
                    arguments: appointment.prescriptionId,
                  ),
                  icon: Icon(Icons.description_outlined, size: 18.sp),
                  label: const Text('View Prescription'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],

            // Invoice button
            if (appointment.paymentMethod != null) ...[
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showInvoiceBottomSheet(context, appointment),
                  icon: Icon(Icons.receipt_long, size: 18.sp),
                  label: const Text('View Invoice'),
                ),
              ),
            ],

            // Cancel Button
            if (appointment.canCancel) ...[
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.cancelAppointment(appointment.id),
                  icon: Icon(Icons.cancel, size: 18.sp),
                  label: const Text('Cancel Appointment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInvoiceBottomSheet(BuildContext context, appointment) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Invoice',
                    style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(height: 24.h),

                _buildInvoiceRow('Appointment ID', '#${appointment.id}', isHeader: true),

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 16.h),

                Text(
                  'Doctor Details',
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
                ),

                SizedBox(height: 12.h),

                _buildInvoiceRow('Doctor', appointment.doctor?.name ?? 'N/A'),
                SizedBox(height: 8.h),
                _buildInvoiceRow('Specialty', appointment.doctor?.specialty ?? 'N/A'),

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 16.h),

                Text(
                  'Appointment Details',
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
                ),

                SizedBox(height: 12.h),

                _buildInvoiceRow('Date', Helpers.formatDate(appointment.date)),
                SizedBox(height: 8.h),
                _buildInvoiceRow('Serial Number', '#${appointment.serialNumber}'),
                SizedBox(height: 8.h),
                _buildInvoiceRow(
                  'Type',
                  appointment.isOnline ? 'Online' : 'Offline',
                ),
                SizedBox(height: 8.h),
                _buildInvoiceRow(
                  'Status',
                  appointment.status.toUpperCase(),
                  valueColor: _getStatusColor(appointment.status),
                ),

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 16.h),

                Text(
                  'Payment Information',
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
                ),

                SizedBox(height: 12.h),

                _buildInvoiceRow('Payment Method', appointment.paymentMethodDisplay),
                SizedBox(height: 8.h),
                _buildInvoiceRow(
                  'Payment Status',
                  appointment.paymentStatusDisplay,
                  valueColor: appointment.isPaymentCompleted
                      ? AppColors.success
                      : appointment.isPaymentFailed
                          ? AppColors.error
                          : AppColors.warning,
                ),
                SizedBox(height: 8.h),
                _buildInvoiceRow(
                  'Payment',
                  appointment.isPaidDisplay,
                  valueColor: appointment.isPaidStatus ? AppColors.success : AppColors.error,
                ),

                if (appointment.transactionId != null) ...[
                  SizedBox(height: 8.h),
                  _buildInvoiceRow('Transaction ID', appointment.transactionId!),
                ],
                if (appointment.bankTransactionId != null) ...[
                  SizedBox(height: 8.h),
                  _buildInvoiceRow('Bank Transaction ID', appointment.bankTransactionId!),
                ],
                if (appointment.paidAmount != null) ...[
                  SizedBox(height: 8.h),
                  _buildInvoiceRow(
                    'Paid Amount',
                    '৳${appointment.paidAmount!.toStringAsFixed(2)}',
                    valueColor: AppColors.success,
                  ),
                ],

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 16.h),

                if (appointment.doctor?.fee != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '৳${(appointment.doctor!.fee as num).toStringAsFixed(2)}',
                        style: AppTextStyles.h5.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],

                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16.sp, color: AppColors.textSecondary),
                      SizedBox(width: 8.w),
                      Text(
                        'Booked on: ${Helpers.formatDate(appointment.createdAt.toString())}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportInvoiceToPdf(appointment),
                    icon: Icon(Icons.download, size: 18.sp),
                    label: const Text('Export as PDF'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(
    String label,
    String value, {
    bool isHeader = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isHeader
              ? AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isHeader
                ? AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  )
                : AppTextStyles.body2.copyWith(
                    color: valueColor ?? Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'confirmed':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _exportInvoiceToPdf(appointment) async {
    try {
      final pdf = pw.Document();

      PatientModel? patientModel;
      try {
        final authController = Get.find<AuthController>();
        patientModel = authController.currentPatient.value;
      } catch (_) {
        final storageService = Get.find<StorageService>();
        final patientData = storageService.getPatient();
        if (patientData != null) {
          patientModel = PatientModel.fromJson(patientData);
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          theme: pw.ThemeData.base(),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Health Grid', style: pw.TextStyle(fontSize: 16)),
                        pw.SizedBox(height: 5),
                        pw.Text('Professional Healthcare Services', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 8),
                        pw.Text('Phone: +880-XXXXXXXXX', style: pw.TextStyle(fontSize: 9)),
                        pw.Text('Email: info@clinic.com', style: pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28)),
                        pw.SizedBox(height: 10),
                        pw.Text('Invoice #${appointment.id}', style: pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 10),
                        pw.Text('Name: ${patientModel?.name ?? 'N/A'}', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 5),
                        pw.Text('Email: ${patientModel?.email ?? 'N/A'}', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 5),
                        pw.Text('Phone: ${patientModel?.phone ?? 'N/A'}', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 5),
                        pw.Text('Patient ID: ${patientModel?.id ?? 'N/A'}', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE DETAILS', style: pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Date: ${Helpers.formatDate(appointment.createdAt.toString())}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Appointment: ${Helpers.formatDate(appointment.date)}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Status: ${appointment.status.toUpperCase()}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),

                pw.Text('APPOINTMENT DETAILS', style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 10),

                pw.Table(
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(3),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Text('Doctor:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(appointment.doctor?.name ?? 'N/A'),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Specialty:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(appointment.doctor?.specialty ?? 'N/A'),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(Helpers.formatDate(appointment.date)),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Serial Number:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('#${appointment.serialNumber}'),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Type:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(appointment.isOnline ? 'Online' : 'Offline'),
                    ]),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),

                if (appointment.paymentMethod != null) ...[
                  pw.Text('PAYMENT INFORMATION', style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 10),

                  pw.Table(
                    columnWidths: {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(children: [
                        pw.Text('Payment Method:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(appointment.paymentMethodDisplay),
                      ]),
                      pw.TableRow(children: [
                        pw.Text('Payment Status:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(appointment.paymentStatusDisplay),
                      ]),
                      if (appointment.transactionId != null)
                        pw.TableRow(children: [
                          pw.Text('Transaction ID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(appointment.transactionId!),
                        ]),
                      if (appointment.bankTransactionId != null)
                        pw.TableRow(children: [
                          pw.Text('Bank Trans. ID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(appointment.bankTransactionId!),
                        ]),
                      if (appointment.paidAmount != null)
                        pw.TableRow(children: [
                          pw.Text('Paid Amount:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('৳${appointment.paidAmount!.toStringAsFixed(2)}'),
                        ]),
                      if (appointment.isPaid != null)
                        pw.TableRow(children: [
                          pw.Text('Payment:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(appointment.isPaidDisplay),
                        ]),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 20),
                ],

                if (appointment.doctor?.fee != null) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Amount:', style: pw.TextStyle(fontSize: 16)),
                      pw.Text(
                        '৳${(appointment.doctor!.fee as num).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, color: PdfColor.fromHex('34C759')),
                      ),
                    ],
                  ),
                ],

                pw.SizedBox(height: 30),

                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('E5E5EA')),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'Booked on: ${Helpers.formatDate(appointment.createdAt.toString())}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),

                pw.Spacer(),

                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for choosing our healthcare services. Contact us for any queries.',
                    style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('999999')),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'Generated on: ${DateTime.now().toString().split('.')[0]}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('CCCCCC')),
                  ),
                ),
              ],
            );
          },
        ),
      );

      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => await pdf.save(),
          name: 'invoice_apt_${appointment.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
        Helpers.showSuccessSnackbar('Success', 'Invoice exported successfully');
      } on MissingPluginException {
        try {
          await Printing.sharePdf(
            bytes: await pdf.save(),
            filename: 'invoice_apt_${appointment.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          Helpers.showSuccessSnackbar('Success', 'Invoice exported successfully');
        } catch (e) {
          Helpers.showErrorSnackbar('Error', 'Please enable Print permission');
        }
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to export invoice: $e');
      debugPrint('$e');
    }
  }
}
