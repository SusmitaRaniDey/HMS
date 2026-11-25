import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:patient_app/data/models/patient_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
import 'bookings_controller.dart';

class BookingsScreen extends GetView<BookingsController> {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
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
                      selectedColor: AppColors.secondary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.border,
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Bookings List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const LoadingWidget(message: 'Loading bookings...');
              }

              if (controller.filteredBookings.isEmpty) {
                return EmptyState(
                  icon: Icons.science_outlined,
                  title: 'No Bookings',
                  message: controller.selectedFilter.value == 'All'
                      ? 'You haven\'t booked any tests yet'
                      : 'No ${controller.selectedFilter.value.toLowerCase()} bookings',
                  buttonText: 'Book a Test',
                  onButtonPressed: () => Get.offAllNamed(AppRoutes.DIAGNOSTICS),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshBookings,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: controller.filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = controller.filteredBookings[index];
                    return _buildBookingCard(booking, context);
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

  Widget _buildBookingCard(booking, BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.BOOKING_DETAIL, arguments: booking),
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
            // Booking ID
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Booking ID: #${booking.id}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 12.h),

            Row(
              children: [
                // Test Icon
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.biotech,
                    size: 28.sp,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(width: 12.w),

                // Test Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.diagnostic?.testName ?? 'Diagnostic Test',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        booking.diagnostic?.category ?? 'Category',
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
                StatusBadge(status: booking.status),
              ],
            ),

            SizedBox(height: 12.h),

            Divider(color: AppColors.divider),

            SizedBox(height: 12.h),

            // Date and Price
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  Helpers.formatDate(booking.scheduleDate),
                  style: AppTextStyles.body2,
                ),
                const Spacer(),
                if (booking.diagnostic?.price != null) ...[
                  Icon(
                    Icons.attach_money,
                    size: 16.sp,
                    color: AppColors.success,
                  ),
                  Text(
                    booking.diagnostic!.priceText,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

            // Notes (if available)
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Cancel Button (if applicable)
            if (booking.canCancel) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.cancelBooking(booking.id),
                  icon: Icon(Icons.cancel, size: 18.sp),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],

            // View Invoice Button
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showInvoiceBottomSheet(context, booking),
                icon: Icon(Icons.receipt_long, size: 18.sp),
                label: const Text('View Invoice'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceBottomSheet(BuildContext context, booking) {
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
                // Header
                Center(
                  child: Text(
                    'Invoice',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Booking ID
                _buildInvoiceRow(
                  'Booking ID',
                  '#${booking.id}',
                  isHeader: true,
                ),

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 16.h),

                // Test Details
                Text(
                  'Test Details',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 12.h),

                _buildInvoiceRow(
                  'Test Name',
                  booking.diagnostic?.testName ?? 'N/A',
                ),

                SizedBox(height: 8.h),

                _buildInvoiceRow(
                  'Category',
                  booking.diagnostic?.category ?? 'N/A',
                ),

                SizedBox(height: 8.h),

                _buildInvoiceRow(
                  'Department',
                  booking.diagnostic?.department ?? 'N/A',
                ),

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 16.h),

                // Appointment Details
                Text(
                  'Appointment Details',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 12.h),

                _buildInvoiceRow(
                  'Scheduled Date',
                  Helpers.formatDate(booking.scheduleDate),
                ),

                SizedBox(height: 8.h),

                _buildInvoiceRow(
                  'Status',
                  booking.status.toUpperCase(),
                  valueColor: _getStatusColor(booking.status),
                ),

                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _buildInvoiceRow('Notes', booking.notes!),
                ],

                SizedBox(height: 16.h),
                Divider(color: AppColors.divider),
                SizedBox(height: 16.h),

                // Payment Information
                if (booking.paymentMethod != null) ...[
                  Text(
                    'Payment Information',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  _buildInvoiceRow(
                    'Payment Method',
                    booking.paymentMethodDisplay,
                  ),

                  SizedBox(height: 8.h),

                  _buildInvoiceRow(
                    'Payment Status',
                    booking.paymentStatusDisplay,
                    valueColor: booking.isPaymentCompleted
                        ? AppColors.success
                        : booking.isPaymentFailed
                        ? AppColors.error
                        : AppColors.warning,
                  ),

                  SizedBox(height: 8.h),

                  _buildInvoiceRow(
                    'Payment',
                    booking.isPaidDisplay,
                    valueColor: booking.isPaidStatus
                        ? AppColors.success
                        : AppColors.error,
                  ),

                  if (booking.transactionId != null) ...[
                    SizedBox(height: 8.h),
                    _buildInvoiceRow('Transaction ID', booking.transactionId!),
                  ],

                  if (booking.bankTransactionId != null) ...[
                    SizedBox(height: 8.h),
                    _buildInvoiceRow(
                      'Bank Transaction ID',
                      booking.bankTransactionId!,
                    ),
                  ],

                  if (booking.paidAmount != null) ...[
                    SizedBox(height: 8.h),
                    _buildInvoiceRow(
                      'Paid Amount',
                      '৳${booking.paidAmount!.toStringAsFixed(2)}',
                      valueColor: AppColors.success,
                    ),
                  ],

                  SizedBox(height: 16.h),
                  Divider(color: AppColors.divider),
                  SizedBox(height: 16.h),
                ],

                // Amount
                if (booking.diagnostic?.price != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '৳${booking.diagnostic!.price.toStringAsFixed(2)}',
                        style: AppTextStyles.h5.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Show remaining balance if partially paid
                  if (booking.paidAmount != null &&
                      booking.paidAmount! < booking.diagnostic!.price) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '৳${(booking.diagnostic!.price - booking.paidAmount!).toStringAsFixed(2)}',
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 24.h),
                ],

                // Booking Date
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Booked on: ${Helpers.formatDate(booking.createdAt.toString())}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Export PDF Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportInvoiceToPdf(booking),
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
                    color: AppColors.secondary,
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

  Future<void> _exportInvoiceToPdf(booking) async {
    try {
      final pdf = pw.Document();

      // Get patient data from AuthController
      // Fall back to StorageService if not available
      PatientModel? patientModel;
      try {
        final authController = Get.find<AuthController>();
        patientModel = authController.currentPatient.value;
      } catch (e) {
        // AuthController not found, try StorageService
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
                // Header with Patient Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left side - Company/Clinic info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Health Grid',
                          style: pw.TextStyle(fontSize: 16),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Professional Diagnostic Services',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Phone: +92-300-XXXXXXX',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Email: info@clinic.com',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    // Right side - Invoice title
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28)),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Invoice #${booking.id}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Patient and Invoice Information
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Patient Information
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PATIENT INFORMATION',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Name: ${patientModel?.name ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Email: ${patientModel?.email ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Phone: ${patientModel?.phone ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Patient ID: ${patientModel?.id ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    // Invoice Information
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE DETAILS',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Date: ${Helpers.formatDate(booking.createdAt.toString())}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Scheduled: ${Helpers.formatDate(booking.scheduleDate)}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Status: ${booking.status.toUpperCase()}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),

                // Test Details Section
                pw.Text('TEST DETAILS', style: pw.TextStyle(fontSize: 12)),

                pw.SizedBox(height: 10),

                pw.Table(
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(3),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Test Name:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(booking.diagnostic?.testName ?? 'N/A'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Category:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(booking.diagnostic?.category ?? 'N/A'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Department:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(booking.diagnostic?.department ?? 'N/A'),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),

                // Appointment Details Section
                pw.Text(
                  'APPOINTMENT DETAILS',
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 10),

                pw.Table(
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(3),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Scheduled Date:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(Helpers.formatDate(booking.scheduleDate)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Status:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(booking.status.toUpperCase()),
                      ],
                    ),
                    if (booking.notes != null && booking.notes!.isNotEmpty)
                      pw.TableRow(
                        children: [
                          pw.Text(
                            'Notes:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(booking.notes!),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),

                // Payment Information Section (if payment info exists)
                if (booking.paymentMethod != null) ...[
                  pw.Text(
                    'PAYMENT INFORMATION',
                    style: pw.TextStyle(fontSize: 12),
                  ),

                  pw.SizedBox(height: 10),

                  pw.Table(
                    columnWidths: {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Text(
                            'Payment Method:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(booking.paymentMethodDisplay),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Text(
                            'Payment Status:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(booking.paymentStatusDisplay),
                        ],
                      ),
                      if (booking.transactionId != null)
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'Transaction ID:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(booking.transactionId!),
                          ],
                        ),
                      if (booking.bankTransactionId != null)
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'Bank Trans. ID:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(booking.bankTransactionId!),
                          ],
                        ),
                      if (booking.paidAmount != null)
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'Paid Amount:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '৳${booking.paidAmount!.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      if (booking.isPaid != null)
                        pw.TableRow(
                          children: [
                            pw.Text(
                              'Payment:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(booking.isPaidDisplay),
                          ],
                        ),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 20),
                ],

                // Amount Section
                if (booking.diagnostic?.price != null) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Amount:',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        '৳${booking.diagnostic!.price.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColor.fromHex('34C759'),
                        ),
                      ),
                    ],
                  ),

                  // Show remaining balance if partially paid
                  if (booking.paidAmount != null &&
                      booking.paidAmount! < booking.diagnostic!.price) ...[
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Remaining Balance:',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          '৳${(booking.diagnostic!.price - booking.paidAmount!).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColor.fromHex('FF9500'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                pw.SizedBox(height: 30),

                // Booking Date Footer
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('E5E5EA')),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'Booked on: ${Helpers.formatDate(booking.createdAt.toString())}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for using our service. Please contact us for any queries.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromHex('999999'),
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'Generated on: ${DateTime.now().toString().split('.')[0]}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('CCCCCC'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save or print the PDF
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => await pdf.save(),
          name:
              'invoice_${booking.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
        Helpers.showSuccessSnackbar('Success', 'Invoice exported successfully');
      } on MissingPluginException {
        // Fallback: try sharePdf if layoutPdf fails
        try {
          await Printing.sharePdf(
            bytes: await pdf.save(),
            filename:
                'invoice_${booking.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          Helpers.showSuccessSnackbar(
            'Success',
            'Invoice exported successfully',
          );
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
