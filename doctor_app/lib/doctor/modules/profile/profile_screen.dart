import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/doctor_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/doctor_network_image.dart';
import 'profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        titleTextStyle: AppTextStyles.h5.copyWith(color: AppColors.textWhite),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: controller.refreshProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            color: AppColors.textWhite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: AppColors.dashboardGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32.r),
                  bottomRight: Radius.circular(32.r),
                ),
              ),
              child: Obx(() {
                final doc = controller.doctor.value;
                return Column(
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: doc?.profilePic != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: DoctorNetworkImage(
                                imageUrl: doc?.profilePic,
                                fit: BoxFit.cover,
                                width: 50.sp,
                                height: 50.sp,
                                fallback: Icon(
                                  Icons.person,
                                  size: 50.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 50.sp,
                              color: AppColors.primary,
                            ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      doc?.name ?? 'Doctor',
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      doc?.specialty ?? 'Specialty',
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        doc?.degrees ?? 'Degrees',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),

            SizedBox(height: 24.h),

            // Profile Information (Read-Only)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Obx(() {
                    final doc = controller.doctor.value;
                    return Column(
                      children: [
                        _buildInfoCard(
                          icon: Icons.email,
                          label: 'Email',
                          value: doc?.email ?? 'N/A',
                        ),
                        SizedBox(height: 12.h),
                        _buildInfoCard(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: doc?.phone ?? 'N/A',
                        ),
                        SizedBox(height: 12.h),
                        _buildInfoCard(
                          icon: Icons.work_outline,
                          label: 'Experience',
                          value: '${doc?.experience ?? 0} years',
                        ),
                        SizedBox(height: 12.h),
                        _buildInfoCard(
                          icon: Icons.business,
                          label: 'Working At',
                          value: doc?.workingAt ?? 'N/A',
                        ),
                        SizedBox(height: 12.h),
                        _buildInfoCard(
                          icon: Icons.videocam_outlined,
                          label: 'Consultation Fee (Online)',
                          value: doc?.onlineFeeText ?? 'N/A',
                        ),
                        SizedBox(height: 12.h),
                        _buildInfoCard(
                          icon: Icons.local_hospital_outlined,
                          label: 'Consultation Fee (Offline)',
                          value: doc?.offlineFeeText ?? 'N/A',
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Obx(() {
                final doc = controller.doctor.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation Schedules',
                      style: AppTextStyles.h5.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildScheduleCard(
                      title: 'Online Schedule',
                      icon: Icons.videocam_outlined,
                      schedules: doc?.onlineSchedule ?? const [],
                    ),
                    SizedBox(height: 12.h),
                    _buildScheduleCard(
                      title: 'Offline Schedule',
                      icon: Icons.local_hospital_outlined,
                      schedules: doc?.workingDays ?? const [],
                    ),
                  ],
                );
              }),
            ),

            SizedBox(height: 24.h),

            // Menu Items
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => Get.toNamed(AppRoutes.CHANGE_PASSWORD),
                  ),
                  SizedBox(height: 12.h),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences and settings',
                    onTap: () => Get.toNamed(AppRoutes.SETTINGS),
                  ),
                  SizedBox(height: 12.h),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('About'),
                          content: const Text(
                            'Doctor App\nVersion 1.0.0\n\n'
                            'View your appointments and manage your schedule.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out from your account',
                    onTap: controller.logout,
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
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
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required String title,
    required IconData icon,
    required List<DoctorDaySchedule> schedules,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (schedules.isEmpty)
            Text(
              'No schedule configured',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...schedules.map(
              (schedule) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.day,
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${schedule.startTime} - ${schedule.endTime}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
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
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
