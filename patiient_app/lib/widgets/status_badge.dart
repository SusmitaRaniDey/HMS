import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/helpers.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final bool isOutlined;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize,
    this.padding,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Helpers.getStatusColor(status);
    final containerColor = color.withOpacity(0.12);
    final borderColor = color.withOpacity(0.3);

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 6.h,
          ),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : containerColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize ?? 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }
}