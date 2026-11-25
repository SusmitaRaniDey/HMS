import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.color,
    this.textColor,
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primary;
    final buttonTextColor = widget.textColor ?? Colors.white;
    final isDisabled = widget.isLoading || widget.onPressed == null;

    if (widget.isOutlined) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height ?? (widget.isSmall ? 40.h : 56.h),
          child: OutlinedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonColor,
              disabledForegroundColor: AppColors.textDisabled,
              side: BorderSide(
                color: isDisabled ? AppColors.border : buttonColor,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  widget.isSmall ? 8.r : 12.r,
                ),
              ),
              animationDuration: const Duration(milliseconds: 300),
            ),
            child: _buildButtonContent(buttonColor),
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? (widget.isSmall ? 40.h : 56.h),
        child: ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: isDisabled
                    ? AppColors.textDisabled
                    : buttonColor,
                foregroundColor: buttonTextColor,
                disabledBackgroundColor: AppColors.textDisabled,
                disabledForegroundColor: AppColors.textHint,
                elevation: isDisabled ? 0 : 2,
                shadowColor: AppColors.shadowMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    widget.isSmall ? 8.r : 12.r,
                  ),
                ),
                animationDuration: const Duration(milliseconds: 300),
              ).copyWith(
                elevation: WidgetStateProperty.resolveWith<double>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.pressed)) {
                    return 4;
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return 3;
                  }
                  if (states.contains(WidgetState.disabled)) {
                    return 0;
                  }
                  return 2;
                }),
              ),
          child: _buildButtonContent(buttonTextColor),
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color contentColor) {
    if (widget.isLoading) {
      return SizedBox(
        height: (widget.isSmall ? 16 : 20).h,
        width: (widget.isSmall ? 16 : 20).w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: widget.isSmall ? 18.sp : 20.sp),
          SizedBox(width: 8.w),
          Text(
            widget.text,
            style: widget.isSmall
                ? AppTextStyles.labelSmall.copyWith(color: contentColor)
                : AppTextStyles.button.copyWith(color: contentColor),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: widget.isSmall
          ? AppTextStyles.labelSmall.copyWith(color: contentColor)
          : AppTextStyles.button.copyWith(color: contentColor),
    );
  }
}
