import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/providers/appointment_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  final AppointmentProvider _provider = AppointmentProvider();
  bool isLoading = false;
  List<dynamic> historyAppointments = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() => isLoading = true);
    try {
      final result = await _provider.getAppointmentHistory();
      setState(() => historyAppointments = result['data']);
    } catch (e) {
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment History'),
      ),
      body: isLoading
          ? const LoadingWidget()
          : historyAppointments.isEmpty
          ? const EmptyState(
        icon: Icons.history,
        title: 'No History',
        message: 'No appointment history available',
      )
          : RefreshIndicator(
        onRefresh: loadHistory,
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: historyAppointments.length,
          itemBuilder: (context, index) {
            final appointment = historyAppointments[index];
            return Container(
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
                              '${Helpers.formatDate(appointment.date)} • ${appointment.timeSlot ?? 'N/A'}',
                              style: AppTextStyles.body2,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: appointment.status),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}