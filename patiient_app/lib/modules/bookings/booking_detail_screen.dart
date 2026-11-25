import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/environment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_badge.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = Get.arguments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: StatusBadge(
                status: booking.status,
                fontSize: 14.sp,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Test Info Card
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                       booking.diagnostic?.image ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.biotech_outlined,
                          size: 28.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.diagnostic?.testName ?? 'Diagnostic Test',
                          style: AppTextStyles.h5.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          booking.diagnostic?.category ?? 'Category',
                          style: AppTextStyles.body1.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        if (booking.diagnostic?.department != null)
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 16.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  booking.diagnostic!.department,
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Booking Details
            Text(
              'Booking Details',
              style: AppTextStyles.h5.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            _buildDetailRow(
              icon: Icons.calendar_today,
              title: 'Schedule Date',
              value: Helpers.formatDate(booking.scheduleDate),
            ),

            SizedBox(height: 12.h),

            _buildDetailRow(
              icon: Icons.info_outline,
              title: 'Status',
              value: booking.status.toUpperCase(),
            ),

            if (booking.diagnostic?.price != null) ...[
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: Icons.attach_money,
                title: 'Price',
                value: booking.diagnostic!.priceText,
                valueColor: AppColors.success,
              ),
            ],

            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: Icons.note,
                title: 'Notes',
                value: booking.notes!,
              ),
            ],

            if (booking.cancellationReason != null) ...[
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: Icons.cancel,
                title: 'Cancellation Reason',
                value: booking.cancellationReason!,
                valueColor: AppColors.error,
              ),
            ],

            // Payment Details
            if (booking.paymentMethod != null) ...[
              SizedBox(height: 24.h),
              Text(
                'Payment Details',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _buildDetailRow(
                icon: Icons.payment,
                title: 'Payment Method',
                value: booking.paymentMethodDisplay,
              ),
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: booking.isPaymentCompleted
                    ? Icons.check_circle
                    : Icons.hourglass_empty,
                title: 'Payment Status',
                value: booking.paymentStatusDisplay,
                valueColor: booking.isPaymentCompleted
                    ? AppColors.success
                    : booking.isPaymentFailed
                    ? AppColors.error
                    : AppColors.warning,
              ),
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: booking.isPaidStatus
                    ? Icons.verified
                    : Icons.pending_outlined,
                title: 'Is Paid',
                value: booking.isPaidDisplay,
                valueColor: booking.isPaidStatus
                    ? AppColors.success
                    : AppColors.warning,
              ),
              if (booking.paidAmount != null) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(
                  icon: Icons.monetization_on,
                  title: 'Amount Paid',
                  value: '৳${booking.paidAmount!.toStringAsFixed(0)}',
                  valueColor: AppColors.success,
                ),
              ],
              if (booking.transactionId != null) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(
                  icon: Icons.receipt,
                  title: 'Transaction ID',
                  value: booking.transactionId!,
                ),
              ],
              if (booking.bankTransactionId != null) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(
                  icon: Icons.account_balance,
                  title: 'Bank Transaction ID',
                  value: booking.bankTransactionId!,
                ),
              ],
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl(
                    '${Environment.BASE_URL}/patient/bookings/${booking.id}/invoice',
                  ),
                  icon: Icon(Icons.receipt_long_rounded, size: 20.sp),
                  label: const Text('View / Download Invoice PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // Test Preparation (if available)
            if (booking.diagnostic?.preparation != null) ...[
              Text(
                'Preparation Instructions',
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20.sp,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        booking.diagnostic!.preparation!,
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // Additional Information
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20.sp,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Important Information',
                        style: AppTextStyles.subtitle2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '• Please arrive 15 minutes before your scheduled time\n'
                        '• Bring your ID and previous test reports if available\n'
                        '• Follow the preparation instructions carefully',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            if (booking.createdAt != null) ...[
              SizedBox(height: 24.h),
              Center(
                child: Text(
                  'Booked on ${Helpers.formatDateTime(booking.createdAt!.toIso8601String())}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Helpers.showErrorSnackbar('Error', 'Could not open the invoice');
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}