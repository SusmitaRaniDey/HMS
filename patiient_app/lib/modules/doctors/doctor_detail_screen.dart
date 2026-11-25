import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/doctor_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/doctor_network_image.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctor = Get.arguments as DoctorModel;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 270.h,
            pinned: true,
            iconTheme: IconThemeData(
              color: AppColors
                  .primaryContainer, // Change this to your desired color
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),

                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 25.h),
                      Container(
                        width: 140.w,
                        height: 140.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 6.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: doctor.profilePic != null
                            ? ClipOval(
                                child: DoctorNetworkImage(
                                  imageUrl: doctor.profilePic,
                                  fit: BoxFit.cover,
                                  fallback: Container(
                                    color: Colors.white,
                                    child: Icon(
                                      Icons.person,
                                      size: 60.sp,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 60.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      SizedBox(height: 10.h),
                      // Doctor name with professional typography
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            Text(
                              '${doctor.name}',
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryContainer,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              doctor.degrees,
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.medical_services,
                          title: 'Specialty',
                          value: doctor.specialty,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.work_outline,
                          title: 'Experience',
                          value: '${doctor.experience} Years',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.business,
                          title: 'Working At',
                          value: doctor.workingAt,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.location_on_outlined,
                          title: 'Consultation Type',
                          value: 'Online & Offline',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.videocam_outlined,
                          title: 'Online Fee',
                          value: doctor.feeTextForType('online'),
                          valueColor: AppColors.success,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.local_hospital_outlined,
                          title: 'Offline Fee',
                          value: doctor.feeTextForType('offline'),
                          valueColor: AppColors.success,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Biography
                  Text(
                    'About Doctor',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  Text(
                    doctor.biography,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  Text(
                    'Consultation Schedules',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildScheduleCard(
                    title: 'Online Schedule',
                    icon: Icons.videocam_outlined,
                    schedules: doctor.onlineSchedule,
                  ),
                  SizedBox(height: 12.h),
                  _buildScheduleCard(
                    title: 'Offline Schedule',
                    icon: Icons.local_hospital_outlined,
                    schedules: doctor.workingDays,
                  ),

                  SizedBox(height: 32.h),

                  // Book Button
                  CustomButton(
                    text: 'Book Appointment',
                    icon: Icons.calendar_today,
                    onPressed: () => Get.toNamed(
                      AppRoutes.BOOK_APPOINTMENT,
                      arguments: doctor,
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
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
          Icon(icon, size: 32.sp, color: AppColors.primary),
          SizedBox(height: 8.h),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required String title,
    required IconData icon,
    required List<DoctorConsultationSchedule> schedules,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
}
