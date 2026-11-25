import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/environment.dart';
import '../../data/models/refund_request_model.dart';
import '../../data/providers/appointment_provider.dart';
import '../../data/providers/refund_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_badge.dart';
import 'appointments_controller.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final RefundProvider _refundProvider = RefundProvider();
  final AppointmentProvider _appointmentProvider = AppointmentProvider();
  late final dynamic appointment;
  late Future<RefundRequestModel?> _refundFuture;

  @override
  void initState() {
    super.initState();
    appointment = Get.arguments;
    _refundFuture = _refundProvider.getByAppointment(appointment.id as int);
  }

  void _reloadRefund() {
    setState(() {
      _refundFuture = _refundProvider.getByAppointment(appointment.id as int);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppointmentsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                alignment: WrapAlignment.center,
                children: [
                  StatusBadge(
                    status: appointment.status,
                    fontSize: 14.sp,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                  ),
                  FutureBuilder<RefundRequestModel?>(
                    future: _refundFuture,
                    builder: (context, snapshot) {
                      final refund = snapshot.data;
                      if (refund == null) return const SizedBox.shrink();
                      return _buildRefundStatusBadge(refund.status);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Doctor Info Card
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
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
                    child: Icon(
                      Icons.person,
                      size: 36.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctor?.name ?? 'Doctor',
                          style: AppTextStyles.h5.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          appointment.doctor?.specialty ?? 'Specialty',
                          style: AppTextStyles.body1.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        if (appointment.doctor?.workingAt != null)
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
                                  appointment.doctor!.workingAt,
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

            // Appointment Details
            Text(
              'Appointment Details',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16.h),

            _buildDetailRow(
              icon: Icons.calendar_today,
              title: 'Date',
              value: Helpers.formatDate(appointment.date),
            ),

            SizedBox(height: 12.h),

            _buildDetailRow(
              icon: Icons.queue,
              title: 'Serial Number',
              value: 'Serial #${appointment.serialNumber}',
            ),

            SizedBox(height: 12.h),

            _buildTimeSection(appointment, controller),

            SizedBox(height: 12.h),

            _buildDetailRow(
              icon: Icons.info_outline,
              title: 'Status',
              value: appointment.status.toUpperCase(),
            ),

            if (appointment.cancellationReason != null) ...[
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: Icons.cancel,
                title: 'Cancellation Reason',
                value: appointment.cancellationReason!,
                valueColor: AppColors.error,
              ),
            ],

            if (appointment.isOnline && !appointment.isAppointmentPast) ...[
              SizedBox(height: 24.h),
              Text(
                'Online Consultation',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _buildDetailRow(
                icon: Icons.video_call_rounded,
                title: 'Meeting Status',
                value: appointment.hasMeeting
                    ? (appointment.meetingStatus ?? 'scheduled').toUpperCase()
                    : 'Waiting for admin confirmation',
                valueColor: appointment.hasMeeting
                    ? AppColors.success
                    : AppColors.warning,
              ),
              if (appointment.zoomPassword != null &&
                  appointment.zoomPassword!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(
                  icon: Icons.lock_outline,
                  title: 'Zoom Password',
                  value: appointment.zoomPassword!,
                ),
              ],
              if (appointment.canJoinMeeting) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _joinZoomMeeting(),
                    icon: Icon(Icons.videocam_rounded, size: 20.sp),
                    label: const Text('Join Zoom Meeting'),
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
            ],

            if (appointment.prescriptionId != null) ...[
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl(
                    '${Environment.BASE_URL}/prescriptions/${appointment.prescriptionId}/download',
                  ),
                  icon: Icon(Icons.picture_as_pdf_rounded, size: 20.sp),
                  label: const Text('View / Download Prescription PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // Payment Details
            if (appointment.paymentMethod != null) ...[
              Text(
                'Payment Details',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _buildDetailRow(
                icon: Icons.payment,
                title: 'Payment Method',
                value: appointment.paymentMethodDisplay,
              ),
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: appointment.isPaymentCompleted
                    ? Icons.check_circle
                    : Icons.hourglass_empty,
                title: 'Payment Status',
                value: appointment.paymentStatusDisplay,
                valueColor: appointment.isPaymentCompleted
                    ? AppColors.success
                    : appointment.isPaymentFailed
                    ? AppColors.error
                    : AppColors.warning,
              ),
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: appointment.isPaidStatus
                    ? Icons.verified
                    : Icons.pending_outlined,
                title: 'Is Paid',
                value: appointment.isPaidDisplay,
                valueColor: appointment.isPaidStatus
                    ? AppColors.success
                    : AppColors.warning,
              ),
              if (appointment.paidAmount != null) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(
                  icon: Icons.monetization_on,
                  title: 'Amount Paid',
                  value: '৳${appointment.paidAmount!.toStringAsFixed(0)}',
                  valueColor: AppColors.success,
                ),
              ],
              if (appointment.transactionId != null) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(
                  icon: Icons.receipt,
                  title: 'Transaction ID',
                  value: appointment.transactionId!,
                ),
              ],
              if (appointment.bankTransactionId != null) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(
                  icon: Icons.account_balance,
                  title: 'Bank Transaction ID',
                  value: appointment.bankTransactionId!,
                ),
              ],
              SizedBox(height: 16.h),
              FutureBuilder<RefundRequestModel?>(
                future: _refundFuture,
                builder: (context, snapshot) {
                  final refund = snapshot.data;
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(
                            '${Environment.BASE_URL}/patient/appointments/${appointment.id}/invoice',
                          ),
                          icon: Icon(Icons.receipt_long_rounded, size: 20.sp),
                          label: const Text('Invoice PDF'),
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
                      if (refund == null && _canRequestRefund(appointment)) ...[
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showRefundSheet(context),
                            icon: Icon(Icons.payments_rounded, size: 20.sp),
                            label: const Text('Request Refund'),
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
                    ],
                  );
                },
              ),
              FutureBuilder<RefundRequestModel?>(
                future: _refundFuture,
                builder: (context, snapshot) {
                  final refund = snapshot.data;
                  if (refund == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: _buildDetailRow(
                      icon: Icons.assignment_return_rounded,
                      title: 'Refund Status',
                      value: refund.statusLabel,
                      valueColor: _refundColor(refund.status),
                    ),
                  );
                },
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
                    '• Please arrive 15 minutes before your appointment time\n'
                    '• Bring your medical records and previous prescriptions\n'
                    '• Inform the doctor about any allergies or current medications',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            if (appointment.createdAt != null) ...[
              SizedBox(height: 24.h),
              Center(
                child: Text(
                  'Booked on ${Helpers.formatDateTime(appointment.createdAt!.toIso8601String())}',
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
      Helpers.showErrorSnackbar('Error', 'Could not open Zoom meeting');
    }
  }

  Future<void> _joinZoomMeeting() async {
    try {
      final url = await _appointmentProvider.getMeetingJoinUrl(
        appointment.id as int,
      );
      setState(() {
        appointment.meetingStatus = 'started';
      });
      await _launchUrl(url);
    } catch (e) {
      Helpers.showErrorSnackbar('Meeting unavailable', e.toString());
    }
  }

  bool _canRequestRefund(dynamic appointment) {
    final isPaid =
        appointment.isPaidStatus == true ||
        appointment.isPaymentCompleted == true ||
        appointment.paymentStatus?.toString().toLowerCase() == 'paid';
    if (!isPaid) return false;

    final meetingFinished =
        appointment.meetingStatus?.toString().toLowerCase() == 'ended' ||
        appointment.meetingStatus?.toString().toLowerCase() == 'started' ||
        appointment.status?.toString().toLowerCase() == 'completed';
    if (meetingFinished) return false;

    final date = DateTime.tryParse(appointment.date as String);
    final isPast =
        date != null &&
        DateTime(date.year, date.month, date.day).isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        );
    if (isPast) return false;

    final isFutureOrToday =
        date == null ||
        !DateTime(date.year, date.month, date.day).isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        );
    final patientCancelledBeforeDate =
        appointment.isCancelled == true && isFutureOrToday;
    final doctorNoShow =
        appointment.isOnline == true && appointment.meetingStatus != 'ended';
    final noConsultation =
        appointment.isCompleted != true && appointment.prescriptionId == null;

    return patientCancelledBeforeDate || doctorNoShow || noConsultation;
  }

  Future<void> _showRefundSheet(BuildContext context) async {
    const reasons = {
      'patient_cancelled': 'I cancelled the appointment',
      'doctor_no_show': "Doctor didn't join",
      'no_consultation': 'No consultation happened',
    };
    var selectedReason = reasons.keys.first;
    final noteController = TextEditingController();
    final accountController = TextEditingController();
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Refund',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
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
                      labelText: 'Additional note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(
                      labelText: 'Your payment account number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (accountController.text.trim().isEmpty) {
                                Helpers.showErrorSnackbar(
                                  'Error',
                                  'Please enter your refund account number',
                                );
                                return;
                              }
                              setSheetState(() => isSubmitting = true);
                              try {
                                await _refundProvider.create(
                                  appointmentId: appointment.id as int,
                                  reason: selectedReason,
                                  patientNote: noteController.text.trim(),
                                  refundToAccount:
                                      accountController.text.trim(),
                                );
                                if (context.mounted) Navigator.pop(context);
                                _reloadRefund();
                                Helpers.showSuccessSnackbar(
                                  'Success',
                                  'Refund request submitted',
                                );
                              } catch (e) {
                                setSheetState(() => isSubmitting = false);
                                Helpers.showErrorSnackbar(
                                  'Error',
                                  e.toString(),
                                );
                              }
                            },
                      child: isSubmitting
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
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

  Widget _buildRefundStatusBadge(String status) {
    final label = switch (status) {
      'processing' => 'Processing',
      'refunded' => 'Refunded',
      'rejected' => 'Rejected',
      _ => 'Pending',
    };
    final icon = switch (status) {
      'processing' => Icons.sync_rounded,
      'refunded' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.circle_rounded,
    };
    final color = _refundColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _refundColor(String status) {
    switch (status) {
      case 'processing':
        return AppColors.info;
      case 'refunded':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildTimeSection(appointment, AppointmentsController controller) {
    // Online appointment: show the specific meeting startTime in local timezone
    if (appointment.isOnline && appointment.startTime != null) {
      try {
        final dt = DateTime.parse(appointment.startTime as String).toLocal();
        final formatted = DateFormat('hh:mm a, dd MMM yyyy').format(dt);
        return _buildDetailRow(
          icon: Icons.access_time,
          title: 'Meeting Time',
          value: formatted,
        );
      } catch (_) {}
    }

    // Offline (or online without startTime): fetch clinic hours from schedule
    return FutureBuilder<Map<String, dynamic>?>(
      future: controller.getDoctorSchedule(appointment.doctor.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailRow(
            icon: Icons.access_time,
            title: 'Clinic Hours',
            value: 'Loading...',
          );
        }
        try {
          final schedule = snapshot.data;
          if (schedule == null) {
            return _buildDetailRow(
              icon: Icons.access_time,
              title: 'Clinic Hours',
              value: 'N/A',
            );
          }
          final workingDays = schedule['workingDays'] as List?;
          if (workingDays == null || workingDays.isEmpty) {
            return _buildDetailRow(
              icon: Icons.access_time,
              title: 'Clinic Hours',
              value: 'N/A',
            );
          }
          final dayName = DateFormat(
            'EEEE',
          ).format(DateTime.parse(appointment.date as String));
          Map<String, dynamic>? matchingDay;
          for (final day in workingDays) {
            if (day is Map<String, dynamic> && day['day'] == dayName) {
              matchingDay = day;
              break;
            }
          }
          final start = matchingDay?['startTime'] as String?;
          final end = matchingDay?['endTime'] as String?;
          return _buildDetailRow(
            icon: Icons.access_time,
            title: 'Clinic Hours',
            value: (start != null && end != null) ? '$start - $end' : 'N/A',
          );
        } catch (_) {
          return _buildDetailRow(
            icon: Icons.access_time,
            title: 'Clinic Hours',
            value: 'N/A',
          );
        }
      },
    );
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 20.sp, color: AppColors.primary),
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
