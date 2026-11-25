import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'appointment_controller.dart';

class AppointmentsScreen extends GetView<DoctorAppointmentsController> {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Appointments'),
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
                    final isSelected = controller.selectedFilter.value == filter;
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
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Appointments List (VIEW-ONLY - No action buttons)
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
                      ? 'No appointments found'
                      : 'No ${controller.selectedFilter.value.toLowerCase()} appointments',
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshAppointments,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: controller.filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = controller.filteredAppointments[index];
                    return _buildAppointmentCard(appointment);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildAppointmentCard(appointment) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Patient Avatar
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        appointment.patient?.contactInfo ?? 'No contact',
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
                Icon(
                  Icons.access_time,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  appointment.timeSlot ?? 'N/A',
                  style: AppTextStyles.body2,
                ),
              ],
            ),

            // NO ACTION BUTTONS - VIEW ONLY
          ],
        ),
      ),
    );
  }
}