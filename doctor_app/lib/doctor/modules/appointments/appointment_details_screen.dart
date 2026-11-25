import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_badge.dart';
import '../../data/providers/appointment_provider.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late final dynamic appointment;
  bool _startingMeeting = false;

  @override
  void initState() {
    super.initState();
    appointment = Get.arguments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Appointment Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: StatusBadge(
                status: appointment.status,
                fontSize: 14.sp,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),

            SizedBox(height: 24.h),

            // Patient Info Card
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
                          appointment.patient?.name ?? 'Patient',
                          style: AppTextStyles.h5.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        if (appointment.patient?.email != null)
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 16.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  appointment.patient!.email!,
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (appointment.patient?.phone != null) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                appointment.patient!.phone!,
                                style: AppTextStyles.body2.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Appointment Details (VIEW-ONLY)
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
              icon: Icons.access_time,
              title: appointment.isOnline ? 'Meeting Time' : 'Time',
              value: _formatTime(appointment),
            ),

            SizedBox(height: 12.h),

            _buildDetailRow(
              icon: Icons.info_outline,
              title: 'Status',
              value: appointment.status.toUpperCase(),
            ),

            if (appointment.rejectionReason != null) ...[
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: Icons.cancel,
                title: 'Rejection Reason',
                value: appointment.rejectionReason!,
                valueColor: AppColors.error,
              ),
            ],

            if (appointment.cancellationReason != null) ...[
              SizedBox(height: 12.h),
              _buildDetailRow(
                icon: Icons.cancel,
                title: 'Cancellation Reason',
                value: appointment.cancellationReason!,
                valueColor: AppColors.error,
              ),
            ],

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

            // ── Online-only meeting actions ─────────────────────────────
            if (appointment.isOnline && !appointment.isAppointmentPast) ...[
              // Start Meeting (host link)
              if (appointment.canStartMeeting) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startingMeeting
                        ? null
                        : () => _startMeeting(appointment.id as int),
                    icon: _startingMeeting
                        ? SizedBox(
                            width: 18.sp,
                            height: 18.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.videocam_rounded, size: 20.sp),
                    label: Text(
                      _startingMeeting ? 'Starting...' : 'Start Meeting',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // Meeting status chip
              if (appointment.meetingStatus != null) ...[
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: appointment.meetingEnded
                          ? AppColors.errorLight
                          : AppColors.successLight,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Meeting: ${appointment.meetingStatus!.toUpperCase()}',
                      style: AppTextStyles.caption.copyWith(
                        color: appointment.meetingEnded
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ],

            // ── Prescription actions (online or offline appointments) ──
            // Write Prescription (once confirmed/completed, regardless of
            // appointment type — offline/in-clinic visits can be
            // prescribed for too).
            if (appointment.canWritePrescription) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.PRESCRIPTION_FORM,
                    arguments: appointment,
                  ),
                  icon: Icon(Icons.edit_document, size: 20.sp),
                  label: const Text('Write Prescription'),
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
              SizedBox(height: 12.h),
            ],

            // Prescription already written indicator
            if (appointment.prescriptionId != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Prescription written',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  String _formatTime(appointment) {
    if (appointment.isOnline && appointment.startTime != null) {
      try {
        final dt = DateTime.parse(appointment.startTime as String).toLocal();
        return DateFormat('hh:mm a, dd MMM yyyy').format(dt);
      } catch (_) {}
    }
    return appointment.timeSlot ?? 'N/A';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Helpers.showErrorSnackbar('Error', 'Could not open Zoom meeting');
    }
  }

  Future<void> _startMeeting(int appointmentId) async {
    if (_startingMeeting) return;
    setState(() => _startingMeeting = true);
    try {
      final url = await AppointmentProvider().getMeetingStartUrl(appointmentId);
      setState(() {
        appointment.meetingStatus = 'started';
      });
      await _launchUrl(url);
    } catch (e) {
      Helpers.showErrorSnackbar('Meeting unavailable', e.toString());
    } finally {
      if (mounted) setState(() => _startingMeeting = false);
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
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
