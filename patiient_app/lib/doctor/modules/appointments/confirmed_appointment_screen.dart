import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/providers/appointment_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'package:get/get.dart';

class ConfirmedAppointmentsScreen extends StatefulWidget {
  const ConfirmedAppointmentsScreen({super.key});

  @override
  State<ConfirmedAppointmentsScreen> createState() => _ConfirmedAppointmentsScreenState();
}

class _ConfirmedAppointmentsScreenState extends State<ConfirmedAppointmentsScreen> {
  final AppointmentProvider _provider = AppointmentProvider();
  bool isLoading = false;
  List<dynamic> confirmedAppointments = [];

  @override
  void initState() {
    super.initState();
    loadConfirmed();
  }

  Future<void> loadConfirmed() async {
    setState(() => isLoading = true);
    try {
      final appointments = await _provider.getConfirmedAppointments();
      setState(() => confirmedAppointments = appointments);
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
        title: const Text('Confirmed Appointments'),
      ),
      body: isLoading
          ? const LoadingWidget()
          : confirmedAppointments.isEmpty
          ? const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Confirmed Appointments',
        message: 'No confirmed appointments found',
      )
          : RefreshIndicator(
        onRefresh: loadConfirmed,
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: confirmedAppointments.length,
          itemBuilder: (context, index) {
            final appointment = confirmedAppointments[index];
            return GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.APPOINTMENT_DETAIL,
                arguments: appointment,
              ),
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
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 28.sp,
                        color: AppColors.success,
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
              ),
            );
          },
        ),
      ),
    );
  }
}