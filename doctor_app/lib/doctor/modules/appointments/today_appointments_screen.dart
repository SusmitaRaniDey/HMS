import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/providers/appointment_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';

class TodayAppointmentsScreen extends StatefulWidget {
  const TodayAppointmentsScreen({super.key});

  @override
  State<TodayAppointmentsScreen> createState() =>
      _TodayAppointmentsScreenState();
}

class _TodayAppointmentsScreenState extends State<TodayAppointmentsScreen> {
  final AppointmentProvider _provider = AppointmentProvider();
  bool isLoading = false;
  List<dynamic> todayAppointments = [];

  @override
  void initState() {
    super.initState();
    loadToday();
  }

  Future<void> loadToday() async {
    setState(() => isLoading = true);
    try {
      final appointments = await _provider.getTodayAppointments();
      setState(() => todayAppointments = appointments);
    } catch (e) {
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text("Today's Schedule")),
      body: isLoading
          ? const LoadingWidget()
          : todayAppointments.isEmpty
          ? const EmptyState(
              icon: Icons.today,
              title: 'No Appointments Today',
              message: 'You have no appointments scheduled for today',
            )
          : RefreshIndicator(
              onRefresh: loadToday,
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: todayAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = todayAppointments[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Time
                        Container(
                          width: 70.w,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppColors.primary,
                                size: 24.sp,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                appointment.timeSlot?.split(' ')[0] ?? 'N/A',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Patient Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.patient?.name ?? 'Patient',
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                appointment.patient?.contactInfo ??
                                    'No contact',
                                style: AppTextStyles.body2,
                              ),
                            ],
                          ),
                        ),

                        // Status
                        StatusBadge(status: appointment.status),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
