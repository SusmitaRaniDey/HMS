import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/auth_controller.dart';
import '../services/storage_services.dart';
import '../utils/app_colors.dart';

// E-Health dashboard sidebar color tokens
const _kOrange = Color(0xFFFF6B35);

class AdminSidebar extends StatelessWidget {
  final String selectedRoute;

  const AdminSidebar({super.key, required this.selectedRoute});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    // Only admins who can manage other admins (super_admin) should even see
    // the Staff nav item — everyone else can't reach staff creation/role
    // management UI by direct URL navigation being the only remaining gap.
    final canManageAdmins =
        Get.find<StorageService>().getAdminModel()?.canManageAdmins ?? false;
    final isCompact = MediaQuery.sizeOf(context).width < 900;
    final sidebarWidth = isCompact ? 96.w : 276.w;

    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 20,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Logo Section ──────────────────────────────────────────────────
          Container(
            height: isCompact ? 78.h : 86.h,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12.w : 20.w),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: isCompact ? 38.w : 42.w,
                  height: isCompact ? 38.w : 42.w,
                  decoration: BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: isCompact ? 18.sp : 20.sp,
                  ),
                ),
                SizedBox(width: isCompact ? 8.w : 12.w),
                if (!isCompact)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HealthGrid',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 10.h),

          // ── Navigation Items ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: '/dashboard',
                  selected: selectedRoute,
                  onTap: () => Get.offAllNamed('/dashboard'),
                ),
                _NavItem(
                  icon: Icons.calendar_today_rounded,
                  title: 'Appointment',
                  route: '/appointments',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/appointments'),
                ),
                _NavItem(
                  icon: Icons.assignment_return_rounded,
                  title: 'Refunds',
                  route: '/refunds',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/refunds'),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'Billing',
                  route: '/billing',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/billing'),
                ),
                /* _NavItem(
                  icon: Icons.local_hospital_rounded,
                  title: 'Departments',
                  route: '/departments',
                  selected: selectedRoute,
                  onTap: () => Get.snackbar(
                    'Coming Soon',
                    'Departments module is under development',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: _kOrange,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  ),
                ), */
                _NavItem(
                  icon: Icons.medical_services_rounded,
                  title: 'Doctors',
                  route: '/doctors',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/doctors'),
                ),
                _NavItem(
                  icon: Icons.emergency_rounded,
                  title: 'Emergency Doctors',
                  route: '/emergency-doctors',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/emergency-doctors'),
                ),
                _NavItem(
                  icon: Icons.people_alt_rounded,
                  title: 'Patients',
                  route: '/users',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/users'),
                ),
                _NavItem(
                  icon: Icons.medication_rounded,
                  title: 'Medicine',
                  route: '/medicines',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/medicines'),
                ),
                if (canManageAdmins)
                  _NavItem(
                    icon: Icons.groups_rounded,
                    title: 'Our Staff',
                    route: '/staff',
                    selected: selectedRoute,
                    onTap: () => Get.toNamed('/staff'),
                  ),
                SizedBox(height: 6.h),
                const Divider(color: AppColors.border, height: 1),
                SizedBox(height: 6.h),
                _NavItem(
                  icon: Icons.science_rounded,
                  title: 'Diagnostics',
                  route: '/diagnostics',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/diagnostics'),
                ),
                _NavItem(
                  icon: Icons.biotech_rounded,
                  title: 'Diag. Bookings',
                  route: '/diagnostic-bookings',
                  selected: selectedRoute,
                  onTap: () => Get.toNamed('/diagnostic-bookings'),
                ),
                SizedBox(height: 6.h),
                const Divider(color: AppColors.border, height: 1),
                SizedBox(height: 6.h),
                /* _NavItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  route: '/settings',
                  selected: selectedRoute,
                  onTap: () => Get.snackbar(
                    'Coming Soon',
                    'Settings module is under development',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: _kOrange,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  ),
                ), */
                _NavItem(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  route: '/logout',
                  selected: selectedRoute,
                  onTap: () => authController.logout(),
                  isDestructive: true,
                ),
              ],
            ),
          ),

          // ── Register Patients Button ──────────────────────────────────────
          /* Container(
            margin: EdgeInsets.all(12.w),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.snackbar(
                  'Coming Soon',
                  'Patient registration module is under development',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: _kOrange,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                ),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kOrange.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: _kOrange, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text(
                        'Register Patients',
                        style: TextStyle(
                          color: _kOrange,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ), */
        ],
      ),
    );
  }
}

// ─── Nav Item Widget ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String selected;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.selected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == route;
    final iconColor = isDestructive
        ? AppColors.error
        : isActive
        ? Colors.white
        : AppColors.textSecondary;
    final textColor = isDestructive
        ? AppColors.error
        : isActive
        ? Colors.white
        : AppColors.textPrimary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          hoverColor: AppColors.primary.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: isActive ? AppColors.sidebarActive : Colors.transparent,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.sidebarActive.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.sp,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
