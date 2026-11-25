import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/doctor_network_image.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        onRefresh: controller.refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCards(),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.EMERGENCY_CONSULTATION),
                      icon: const Icon(Icons.emergency_rounded),
                      label: const Text('Emergency Consultation'),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _buildSectionHeader(
                    'Confirmed Appointments',
                    onViewAll: () =>
                        Get.toNamed(AppRoutes.CONFIRMED_APPOINTMENTS),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() {
                    if (controller.confirmedError.value &&
                        controller.confirmedAppointments.isEmpty) {
                      return _buildErrorCard(
                        'Could not load confirmed appointments',
                        controller.loadConfirmedAppointments,
                      );
                    }

                    if (controller.confirmedAppointments.isEmpty) {
                      return _buildEmptyCard(
                        'No confirmed appointments',
                        Icons.event_available,
                      );
                    }

                    return Column(
                      children: controller.confirmedAppointments
                          .map(_buildAppointmentCard)
                          .toList(),
                    );
                  }),
                  SizedBox(height: 24.h),
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

                    if (controller.pendingError.value &&
                        controller.pendingAppointments.isEmpty) {
                      return _buildErrorCard(
                        'Could not load pending requests',
                        controller.loadPendingAppointments,
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
                          .map(_buildAppointmentCard)
                          .toList(),
                    );
                  }),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 24.h),
      decoration: BoxDecoration(
        gradient: AppColors.dashboardGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDoctorHeader(),
          SizedBox(height: 26.h),
          Text(
            'Let\'s keep your schedule\nclear and ready.',
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          SizedBox(height: 24.h),
          _buildNextAppointmentsPanel(),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Obx(() {
                    final profilePic =
                        controller.currentDoctor.value?.profilePic;
                    if (profilePic != null && profilePic.isNotEmpty) {
                      return ClipOval(
                        child: DoctorNetworkImage(
                          imageUrl: profilePic,
                          width: 44.w,
                          height: 44.w,
                          fit: BoxFit.cover,
                          fallback: Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 25.sp,
                          ),
                        ),
                      );
                    }
                    return Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 25.sp,
                    );
                  }),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hi ${controller.getDoctorName()}',
                          style: AppTextStyles.subtitle2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          controller.getGreeting(),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        _buildHeaderIcon(
          Icons.chat_bubble_outline,
          onTap: () => Helpers.showInfoSnackbar('Chat', 'Chat is coming soon'),
        ),
        SizedBox(width: 10.w),
        _buildHeaderIcon(
          Icons.notifications_none,
          onTap: () => Helpers.showInfoSnackbar(
            'Notifications',
            'Notifications are coming soon',
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.24),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22.sp),
      ),
    );
  }

  Widget _buildNextAppointmentsPanel() {
    return Obx(() {
      final appointments = controller.nextAppointments;

      return Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Upcoming Schedule',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${appointments.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            if (appointments.isEmpty)
              _buildNoNextAppointment()
            else
              _buildAppointmentCarousel(appointments),
          ],
        ),
      );
    });
  }

  Widget _buildNoNextAppointment() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.event_available,
              color: AppColors.success,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'No active confirmed appointment is waiting right now.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCarousel(List<dynamic> appointments) {
    return SizedBox(
      height: 142.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: appointments.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          return _buildCarouselAppointmentCard(
            appointments[index],
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildCarouselAppointmentCard(
    dynamic appointment, {
    required int index,
  }) {
    final isFirst = index == 0;
    final accentColor = isFirst ? const Color(0xFFC21F61) : AppColors.primary;

    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.APPOINTMENT_DETAIL, arguments: appointment),
      child: Container(
        width: (Get.width - 74.w).clamp(250.w, 310.w).toDouble(),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isFirst ? const Color(0xFFFFF4F8) : const Color(0xFFF5FBFF),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isFirst ? const Color(0xFFF6C4D8) : const Color(0xFFDCEFFB),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildAppointmentAvatar(appointment, accentColor),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patient?.name ?? 'Patient',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        appointment.isOnline
                            ? 'Online consultation'
                            : 'Clinic appointment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    appointment.isOnline
                        ? Icons.videocam_outlined
                        : Icons.person_outline,
                    color: accentColor,
                    size: 19.sp,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCarouselMeta(
                      Icons.calendar_today_outlined,
                      controller.formatAppointmentDay(appointment),
                      accentColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildCarouselMeta(
                      Icons.access_time,
                      controller.formatAppointmentTime(appointment),
                      accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentAvatar(dynamic appointment, Color accentColor) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.16),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _appointmentInitial(appointment),
          style: AppTextStyles.h5.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselMeta(IconData icon, String label, Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accentColor, size: 14.sp),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }

  String _appointmentInitial(dynamic appointment) {
    final name = appointment.patient?.name ?? 'Patient';
    return name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _buildStatCard(
              'Pending',
              controller.pendingCount.value.toString(),
              Icons.pending_actions,
              AppColors.warning,
              AppColors.warningLight,
              () => Get.toNamed(AppRoutes.PENDING_REQUESTS),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Obx(
            () => _buildStatCard(
              'Confirmed',
              controller.confirmedCount.value.toString(),
              Icons.verified_outlined,
              AppColors.success,
              AppColors.successLight,
              () => Get.toNamed(AppRoutes.CONFIRMED_APPOINTMENTS),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Obx(
            () => _buildStatCard(
              'Today',
              controller.todayCount.value.toString(),
              Icons.today_outlined,
              AppColors.info,
              AppColors.infoLight,
              () => Get.toNamed(AppRoutes.TODAY_APPOINTMENTS),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color background,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 118.h,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 20.sp, color: color),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.APPOINTMENT_DETAIL, arguments: appointment),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                appointment.isOnline ? Icons.videocam : Icons.person,
                color: AppColors.primary,
                size: 26.sp,
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
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${Helpers.formatDate(appointment.date)} - ${appointment.timeSlot ?? 'N/A'}',
                    style: AppTextStyles.body2,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildErrorCard(String message, Future<void> Function() onRetry) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 36.sp, color: AppColors.error),
          SizedBox(height: 10.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42.sp, color: AppColors.textHint),
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
