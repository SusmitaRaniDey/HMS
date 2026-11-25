import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'prescriptions_controller.dart';

class PrescriptionsScreen extends GetView<PrescriptionsController> {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget(message: 'Loading prescriptions...');
        }
        if (controller.prescriptions.isEmpty) {
          return EmptyState(
            icon: Icons.description_outlined,
            title: 'No Prescriptions',
            message: 'Your prescriptions will appear here after a consultation.',
            buttonText: 'Book Appointment',
            onButtonPressed: () => Get.offAllNamed(AppRoutes.DOCTORS),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.prescriptions.length,
            itemBuilder: (_, i) =>
                _PrescriptionCard(prescription: controller.prescriptions[i]),
          ),
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final dateStr = prescription.createdAt != null
        ? DateFormat('dd MMM yyyy').format(prescription.createdAt!)
        : '—';

    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.PRESCRIPTION_DETAIL, arguments: prescription),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
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
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.description_rounded,
                  color: AppColors.primary, size: 28.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${prescription.doctorName}',
                    style: AppTextStyles.subtitle1
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    prescription.diagnosis ?? 'Prescription',
                    style: AppTextStyles.body2
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 13.sp, color: AppColors.textTertiary),
                      SizedBox(width: 4.w),
                      Text(dateStr,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary)),
                      if (prescription.hasPdf) ...[
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text('PDF Ready',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
