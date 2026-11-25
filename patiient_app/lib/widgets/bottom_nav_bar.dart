import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  double _getAdaptiveHeight(double screenHeight) {
    if (screenHeight < 600) return 56.0;
    if (screenHeight < 700) return 64.0;
    return 72.0;
  }

  double _getAdaptiveIconSize(double screenHeight) {
    if (screenHeight < 600) return 18.0;
    if (screenHeight < 700) return 20.0;
    return 24.0;
  }

  double _getAdaptivePadding(double screenHeight) {
    if (screenHeight < 600) return 3.0;
    if (screenHeight < 700) return 4.0;
    return 6.0;
  }

  double _getAdaptiveFontSize(double screenHeight) {
    if (screenHeight < 600) return 8.5;
    if (screenHeight < 700) return 9.5;
    return 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final navBarHeight = _getAdaptiveHeight(screenHeight);
    final iconSize = _getAdaptiveIconSize(screenHeight);
    final verticalPadding = _getAdaptivePadding(screenHeight);
    final fontSize = _getAdaptiveFontSize(screenHeight);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: navBarHeight.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    Get.offAllNamed(AppRoutes.HOME);
                  }
                },
                iconSize: iconSize,
                verticalPadding: verticalPadding,
                fontSize: fontSize,
              ),
              _NavBarItem(
                icon: Icons.medical_services_outlined,
                activeIcon: Icons.medical_services_rounded,
                label: 'Doctors',
                isActive: currentIndex == 1,
                onTap: () {
                  if (currentIndex != 1) {
                    Get.offAllNamed(AppRoutes.DOCTORS);
                  }
                },
                iconSize: iconSize,
                verticalPadding: verticalPadding,
                fontSize: fontSize,
              ),
              _NavBarItem(
                icon: Icons.biotech_outlined,
                activeIcon: Icons.biotech_rounded,
                label: 'Tests',
                isActive: currentIndex == 2,
                onTap: () {
                  if (currentIndex != 2) {
                    Get.offAllNamed(AppRoutes.DIAGNOSTICS);
                  }
                },
                iconSize: iconSize,
                verticalPadding: verticalPadding,
                fontSize: fontSize,
              ),
              _NavBarItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today_rounded,
                label: 'Bookings',
                isActive: currentIndex == 3,
                onTap: () {
                  if (currentIndex != 3) {
                    Get.offAllNamed(AppRoutes.APPOINTMENTS);
                  }
                },
                iconSize: iconSize,
                verticalPadding: verticalPadding,
                fontSize: fontSize,
              ),
              _NavBarItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () {
                  if (currentIndex != 4) {
                    Get.offAllNamed(AppRoutes.PROFILE);
                  }
                },
                iconSize: iconSize,
                verticalPadding: verticalPadding,
                fontSize: fontSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double iconSize;
  final double verticalPadding;
  final double fontSize;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.iconSize,
    required this.verticalPadding,
    required this.fontSize,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _animationController.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: AppColors.ripple,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: widget.verticalPadding.h,
              horizontal: 4.w,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isActive
                          ? AppColors.primaryContainer
                          : Colors.transparent,
                    ),
                    child: Icon(
                      widget.isActive ? widget.activeIcon : widget.icon,
                      color: widget.isActive
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: widget.iconSize.sp,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: widget.fontSize.sp,
                      fontWeight: widget.isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.isActive
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                    ),
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
