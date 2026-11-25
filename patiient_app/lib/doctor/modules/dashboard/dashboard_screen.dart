import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/status_badge.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshDashboard,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.getGreeting(),
                                style: AppTextStyles.body1.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Obx(
                                () => Text(
                                  controller.getDoctorName(),
                                  style: AppTextStyles.h3.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Obx(() {
                            final profilePic = controller.currentDoctor.value?.profilePic;
                            if (profilePic != null && profilePic.isNotEmpty) {
                              return ClipOval(
                                child: Image.network(
                                   profilePic,
                                  width: 50.w,
                                  height: 50.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 28.sp,
                                  ),
                                  ),

                              );
                            }
                            return Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 28.sp,
                            );
                          }),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Statistics Cards (VIEW-ONLY)
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => _buildStatCard(
                              'Pending',
                              controller.pendingCount.value.toString(),
                              Icons.pending_actions,
                              AppColors.warning,
                              () => Get.toNamed(AppRoutes.PENDING_REQUESTS),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Obx(
                            () => _buildStatCard(
                              'Confirmed',
                              controller.confirmedCount.value.toString(),
                              Icons.check_circle_outline,
                              AppColors.success,
                              () => Get.toNamed(
                                AppRoutes.CONFIRMED_APPOINTMENTS,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => _buildStatCard(
                        'Today\'s Appointments',
                        controller.todayCount.value.toString(),
                        Icons.today,
                        AppColors.info,
                        () => Get.toNamed(AppRoutes.TODAY_APPOINTMENTS),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: EdgeInsets.all(24.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                   // Confirmed Appointments Section (VIEW-ONLY)
                  _buildSectionHeader(
                    'Confirmed Appointments',
                    onViewAll: () =>
                        Get.toNamed(AppRoutes.CONFIRMED_APPOINTMENTS),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() {
                    if (controller.confirmedAppointments.isEmpty) {
                      return _buildEmptyCard(
                        'No confirmed appointments',
                        Icons.event_available,
                      );
                    }

                    return Column(
                      children: controller.confirmedAppointments
                          .map(
                            (appointment) =>
                                _buildAppointmentCard(appointment),
                          )
                          .toList(),
                    );
                  }),
                  SizedBox(height: 24.h),


                  // Pending Requests Section (VIEW-ONLY)
                  _buildSectionHeader(
                    'Pending Requests',
                    onViewAll: () => Get.toNamed(AppRoutes.PENDING_REQUESTS),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() {
                    if (controller.isLoading.value &&
                        controller.pendingAppointments.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (controller.pendingAppointments.isEmpty) {
                      return _buildEmptyCard(
                        'No pending requests',
                        Icons.check_circle,
                      );
                    }

                    return Column(
                      children: controller.pendingAppointments
                          .map(
                            (appointment) =>
                                _buildAppointmentCard(appointment),
                          )
                          .toList(),
                    );
                  }),

                 
                 

                  SizedBox(height: 24.h),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.sp, color: Colors.white),
            SizedBox(height: 8.h),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View All',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(appointment) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.APPOINTMENT_DETAIL, arguments: appointment),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.person, color: AppColors.primary, size: 28.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patient?.name ?? 'Patient',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
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
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48.sp, color: AppColors.textHint),
          SizedBox(height: 12.h),
          Text(
            message,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
