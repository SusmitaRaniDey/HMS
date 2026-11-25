import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/doctor_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/doctor_network_image.dart';

class DoctorsListScreen extends GetView<DoctorsController> {
  const DoctorsListScreen({super.key});

  static const _clinicalBlue = Color(0xFF2563EB);
  static const _clinicalTeal = Color(0xFF0F766E);
  static const _pageBackground = Color(0xFFF4F8FB);
  static const _navy = Color(0xFF16324F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/doctors'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, controller),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: _clinicalBlue),
                      );
                    }
                    if (controller.filteredDoctors.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildDoctorsTable(controller);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, DoctorsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(28.w, 20.h, 28.w, 20.h),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5EDF4))),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeading(controller),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(child: _buildSearchField(controller)),
                        SizedBox(width: 12.w),
                        _buildAddButton(),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildHeading(controller)),
                    SizedBox(width: 24.w),
                    SizedBox(
                      width: 330.w,
                      child: _buildSearchField(controller),
                    ),
                    SizedBox(width: 12.w),
                    _buildAddButton(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeading(DoctorsController controller) {
    return Row(
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_clinicalBlue, Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13.r),
            boxShadow: [
              BoxShadow(
                color: _clinicalBlue.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 23.sp,
          ),
        ),
        SizedBox(width: 14.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doctors Management',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 23.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              SizedBox(height: 4.h),
              Obx(
                () => Text(
                  '${controller.filteredDoctors.length} doctors in your care network',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(DoctorsController controller) {
    return SizedBox(
      height: 46.h,
      child: TextField(
        onChanged: controller.searchDoctors,
        style: TextStyle(fontSize: 14.5.sp, color: _navy),
        decoration: InputDecoration(
          hintText: 'Search by doctor or specialty',
          hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontSize: 14.sp),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF64748B),
            size: 21.sp,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFDCE6EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: _clinicalBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 46.h,
      child: ElevatedButton.icon(
        onPressed: () => Get.toNamed('/doctors/add'),
        icon: Icon(Icons.add_rounded, size: 20.sp),
        label: const Text('Add Doctor'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _clinicalBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsTable(DoctorsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 850 ? 16.w : 28.w;
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24.h,
            horizontalPadding,
            24.h,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2EAF1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A16324F),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: availableWidth,
                  minHeight: constraints.maxHeight - 48.h,
                ),
                child: DataTable(
                  horizontalMargin: 24.w,
                  columnSpacing: constraints.maxWidth > 1250 ? 48.w : 30.w,
                  headingRowHeight: 58.h,
                  dataRowMinHeight: 76.h,
                  dataRowMaxHeight: 76.h,
                  dividerThickness: 1,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF1F7FB),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return const Color(0xFFF3F8FF);
                    }
                    return Colors.white;
                  }),
                  columns: const [
                    DataColumn(label: _TableHeading('ID')),
                    DataColumn(label: _TableHeading('DOCTOR')),
                    DataColumn(label: _TableHeading('SPECIALTY')),
                    DataColumn(label: _TableHeading('EXPERIENCE')),
                    DataColumn(label: _TableHeading('CONSULTATION FEE')),
                    DataColumn(label: _TableHeading('APPOINTMENTS')),
                    DataColumn(label: _TableHeading('ACTION')),
                  ],
                  rows: controller.filteredDoctors.map((doctor) {
                    final hasAppointments = (doctor.appointmentsCount ?? 0) > 0;
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '#${doctor.id}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              _DoctorAvatar(
                                imageUrl: doctor.profilePic,
                                initials: _initials(doctor.name),
                              ),
                              SizedBox(width: 11.w),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 190.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      doctor.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _navy,
                                        fontSize: 14.5.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      doctor.degrees,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(_SpecialtyBadge(label: doctor.specialty)),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                Icons.work_history_outlined,
                                size: 16.sp,
                                color: const Color(0xFF7890A5),
                              ),
                              SizedBox(width: 7.w),
                              Text(
                                '${doctor.experience} years',
                                style: TextStyle(color: _navy, fontSize: 14.sp),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '৳${doctor.fee.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: _clinicalTeal,
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DataCell(
                          _AppointmentBadge(
                            count: doctor.appointmentsCount ?? 0,
                            isActive: hasAppointments,
                          ),
                        ),
                        DataCell(
                          Tooltip(
                            message: 'View doctor details',
                            child: InkWell(
                              onTap: () => Get.toNamed(
                                '/doctors/detail',
                                arguments: doctor,
                              ),
                              borderRadius: BorderRadius.circular(9.r),
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: _clinicalBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(9.r),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _clinicalBlue,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'DR';
    final meaningful = words
        .where((word) => word.toLowerCase() != 'dr.')
        .toList();
    final source = meaningful.isEmpty ? words : meaningful;
    return source.take(2).map((word) => word[0].toUpperCase()).join();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFE2EAF1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                color: _clinicalBlue.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_outlined,
                size: 36.sp,
                color: _clinicalBlue,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'No doctors found',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try a different search or add a new doctor.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }
}

class _TableHeading extends StatelessWidget {
  final String label;

  const _TableHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: const Color(0xFF587089),
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;

  const _DoctorAvatar({required this.imageUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 42.w,
      height: 42.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A16324F),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? DoctorNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    fallback: _AvatarInitials(initials),
                  )
                : _AvatarInitials(initials),
          ),
          Positioned(
            right: 0,
            bottom: 1.h,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String initials;

  const _AvatarInitials(this.initials);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFF2563EB),
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SpecialtyBadge extends StatelessWidget {
  final String label;

  const _SpecialtyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF2563EB),
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AppointmentBadge extends StatelessWidget {
  final int count;
  final bool isActive;

  const _AppointmentBadge({required this.count, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF0F766E) : const Color(0xFF718096);
    final background = isActive
        ? const Color(0xFFECFDF5)
        : const Color(0xFFF1F5F9);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 7.w),
          Text(
            isActive
                ? '$count ${count == 1 ? 'Appointment' : 'Appointments'}'
                : 'No appointments',
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
