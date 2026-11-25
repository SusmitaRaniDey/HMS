import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/diagnostic_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'diagnostics_controller.dart';

class DiagnosticsListScreen extends GetView<DiagnosticsController> {
  const DiagnosticsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnostic Tests'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Bar — searches by test name, category, and item code.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: TextField(
              onChanged: controller.searchDiagnostics,
              decoration: InputDecoration(
                hintText: 'Search by test name, category, or item code',
                hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Diagnostics List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.groups.isEmpty) {
                return const LoadingWidget(message: 'Loading diagnostic tests...');
              }

              if (controller.groups.isEmpty) {
                return EmptyState(
                  icon: Icons.science_outlined,
                  title: 'No Tests Found',
                  message: controller.searchQuery.value.isEmpty
                      ? 'No diagnostic tests are available right now'
                      : 'No tests match your search',
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.refreshDiagnostics,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  itemCount: controller.groups.length,
                  itemBuilder: (context, index) {
                    return _DiagnosticCard(group: controller.groups[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

// A single test-panel card — one per unique item_code. Shows only Test
// Name, Category, Price and Parameter count; the whole card is tappable
// and opens the Diagnostic Details screen (Book Now lives there only).
class _DiagnosticCard extends StatelessWidget {
  final DiagnosticGroupModel group;

  const _DiagnosticCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () => Get.toNamed(AppRoutes.DIAGNOSTIC_DETAIL, arguments: group),
        child: Container(
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: group.image != null && group.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Image.network(
                          group.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.biotech_outlined,
                            size: 26.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Icon(Icons.biotech_outlined, color: AppColors.primary, size: 26.sp),
              ),
              SizedBox(width: 14.w),

              // Test Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.testName,
                      style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    _Chip(
                      icon: Icons.category_outlined,
                      label: group.category,
                      color: AppColors.info,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      group.priceText,
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
