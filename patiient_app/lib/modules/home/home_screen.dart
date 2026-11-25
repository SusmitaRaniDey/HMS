import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static const List<String> _fallbackDepartments = [
    'Cardiology',
    'Kidney',
    'Liver',
    'ENT',
    'Neurology',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 22.h),
                      _buildSearchBar(),
                      SizedBox(height: 14.h),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Get.toNamed(AppRoutes.EMERGENCY_DOCTORS),
                          icon: const Icon(Icons.emergency_rounded),
                          label: const Text('Emergency Doctor'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildDepartmentCarousel()),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 0, 28.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Obx(
                      () => _buildSectionHeader(
                        'Upcoming Schedule',
                        count: controller.upcomingAppointments.length,
                        onViewAll: () => Get.toNamed(AppRoutes.APPOINTMENTS),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return _buildLoadingCard();
                      }

                      if (controller.upcomingAppointments.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(right: 24.w),
                          child: _buildEmptyCard(
                            'No upcoming appointments',
                            Icons.calendar_today_rounded,
                          ),
                        );
                      }

                      return SizedBox(
                        height: 172.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(right: 24.w),
                          itemCount: controller.upcomingAppointments.length,
                          separatorBuilder: (_, __) => SizedBox(width: 14.w),
                          itemBuilder: (context, index) {
                            final appointment =
                                controller.upcomingAppointments[index];
                            return _buildAppointmentSlide(appointment);
                          },
                        ),
                      );
                    }),
                    SizedBox(height: 26.h),
                    Obx(
                      () => _buildSectionHeader(
                        'Upcoming Tests',
                        count: controller.upcomingBookings.length,
                        onViewAll: () => Get.toNamed(AppRoutes.BOOKINGS),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() {
                      if (controller.upcomingBookings.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(right: 24.w),
                          child: _buildEmptyCard(
                            'No upcoming tests',
                            Icons.science_rounded,
                          ),
                        );
                      }

                      return SizedBox(
                        height: 154.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(right: 24.w),
                          itemCount: controller.upcomingBookings.length,
                          separatorBuilder: (_, __) => SizedBox(width: 14.w),
                          itemBuilder: (context, index) {
                            final booking = controller.upcomingBookings[index];
                            return _buildTestSlide(booking);
                          },
                        ),
                      );
                    }),
                    SizedBox(height: 24.h),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello ${controller.getPatientName()}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  controller.getGreeting(),
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: () => Get.toNamed(AppRoutes.PROFILE),
            child: SizedBox(
              width: 48.w,
              height: 48.w,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 24.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.DOCTORS),
            child: Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: _softShadow,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Search Doctors',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => Get.toNamed(AppRoutes.DIAGNOSTICS),
            child: SizedBox(
              width: 50.h,
              height: 50.h,
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 24.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentCarousel() {
    return Obx(() {
      final departments = controller.doctorDepartments.isEmpty
          ? _fallbackDepartments
          : controller.doctorDepartments;

      return SizedBox(
        height: 92.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          itemCount: departments.length,
          separatorBuilder: (_, __) => SizedBox(width: 18.w),
          itemBuilder: (context, index) {
            final department = departments[index];
            return _buildDepartmentItem(department);
          },
        ),
      );
    });
  }

  Widget _buildDepartmentItem(String department) {
    final color = _departmentColor(department);

    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.DOCTORS, arguments: {'department': department}),
      child: SizedBox(
        width: 72.w,
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.14)),
                boxShadow: _softShadow,
              ),
              child: Padding(
                padding: EdgeInsets.all(11.w),
                child: CustomPaint(
                  painter: _DepartmentIconPainter(
                    kind: _departmentIconKind(department),
                    color: color,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              department,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    int? count,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 24.w),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                text: title,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                children: [
                  if (count != null)
                    TextSpan(
                      text: ' ($count)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See All',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSlide(dynamic appointment) {
    final profilePic =
        appointment.doctor?.profilePic ??
        (appointment.doctorId != null
            ? controller.doctorProfilePics[appointment.doctorId!]
            : null);

    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.APPOINTMENT_DETAIL, arguments: appointment),
      child: Container(
        width: 292.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: AppColors.appointmentGradient,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildDoctorAvatar(profilePic, size: 54.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctor?.name ?? 'Doctor',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        appointment.doctor?.specialty ?? 'Specialization',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    appointment.isOnline
                        ? Icons.videocam_rounded
                        : Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildScheduleMeta(
                      Icons.calendar_month_rounded,
                      Helpers.formatDate(appointment.date),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildScheduleMeta(
                      Icons.access_time_rounded,
                      _appointmentTime(appointment),
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

  Widget _buildTestSlide(dynamic booking) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.BOOKING_DETAIL, arguments: booking),
      child: Container(
        width: 262.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: _softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 58.w,
              height: 58.w,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                ),
              ),
              child: booking.diagnostic?.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(
                        booking.diagnostic!.image!,
                        width: 58.w,
                        height: 58.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.biotech_rounded,
                          color: AppColors.secondaryDark,
                          size: 28.sp,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.biotech_rounded,
                      color: AppColors.secondaryDark,
                      size: 28.sp,
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    booking.diagnostic?.testName ?? 'Diagnostic Test',
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    booking.diagnostic?.department ?? 'Department',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
                        size: 15.sp,
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          Helpers.formatDate(booking.scheduleDate),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAvatar(String? profilePic, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: profilePic != null && profilePic.isNotEmpty
            ? Image.network(
                profilePic,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 26.sp,
                ),
              )
            : Icon(Icons.person_rounded, color: AppColors.primary, size: 26.sp),
      ),
    );
  }

  Widget _buildScheduleMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 15.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Padding(
      padding: EdgeInsets.only(right: 24.w),
      child: Container(
        height: 150.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: _softShadow,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      height: 132.h,
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: _softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34.sp, color: AppColors.textHint),
          SizedBox(height: 10.h),
          Text(
            message,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _appointmentTime(dynamic appointment) {
    final timeSlot = appointment.timeSlot?.toString();
    if (timeSlot != null && timeSlot.isNotEmpty) {
      return Helpers.formatTime(timeSlot);
    }

    final startTime = appointment.startTime?.toString();
    if (startTime != null && startTime.isNotEmpty) {
      return Helpers.formatDateTime(startTime).split(', ').last;
    }
    return appointment.isOnline ? 'Online' : 'Hospital';
  }

  _DepartmentIconKind _departmentIconKind(String department) {
    final key = department.toLowerCase();
    if (key.contains('cardio') || key.contains('heart')) {
      return _DepartmentIconKind.cardiology;
    }
    if (key.contains('kidney') || key.contains('nephro')) {
      return _DepartmentIconKind.kidney;
    }
    if (key.contains('liver') ||
        key.contains('gastro') ||
        key.contains('digest')) {
      return _DepartmentIconKind.gastroenterology;
    }
    if (key.contains('ent') || key.contains('ear')) {
      return _DepartmentIconKind.ent;
    }
    if (key.contains('eye') || key.contains('ophthal')) {
      return _DepartmentIconKind.eye;
    }
    if (key.contains('neuro')) {
      return _DepartmentIconKind.neurology;
    }
    if (key.contains('dental') || key.contains('dentist')) {
      return _DepartmentIconKind.dental;
    }
    if (key.contains('ortho') || key.contains('bone')) {
      return _DepartmentIconKind.orthopedics;
    }
    if (key.contains('child') || key.contains('pediatric')) {
      return _DepartmentIconKind.pediatrics;
    }
    if (key.contains('gyne') ||
        key.contains('gynae') ||
        key.contains('obstetric') ||
        key.contains('women')) {
      return _DepartmentIconKind.gynecology;
    }
    if (key.contains('skin') || key.contains('derma')) {
      return _DepartmentIconKind.dermatology;
    }
    if (key.contains('lung') ||
        key.contains('pulmo') ||
        key.contains('respiratory')) {
      return _DepartmentIconKind.pulmonology;
    }
    return _DepartmentIconKind.general;
  }

  Color _departmentColor(String department) {
    final key = department.toLowerCase();
    if (key.contains('cardio') || key.contains('heart')) {
      return AppColors.accentRose;
    }
    if (key.contains('kidney') || key.contains('nephro')) {
      return AppColors.accentBlue;
    }
    if (key.contains('liver') || key.contains('gastro')) {
      return AppColors.accentOrange;
    }
    if (key.contains('ent') || key.contains('ear')) {
      return AppColors.accentViolet;
    }
    if (key.contains('eye') || key.contains('ophthal')) {
      return AppColors.secondary;
    }
    if (key.contains('neuro')) {
      return AppColors.accentViolet;
    }
    if (key.contains('dental') || key.contains('dentist')) {
      return AppColors.primary;
    }
    return AppColors.primary;
  }

  List<BoxShadow> get _softShadow => [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

enum _DepartmentIconKind {
  cardiology,
  kidney,
  gastroenterology,
  ent,
  eye,
  neurology,
  dental,
  orthopedics,
  pediatrics,
  gynecology,
  dermatology,
  pulmonology,
  general,
}

class _DepartmentIconPainter extends CustomPainter {
  const _DepartmentIconPainter({required this.kind, required this.color});

  final _DepartmentIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas
      ..save()
      ..translate((size.width - side) / 2, (size.height - side) / 2)
      ..scale(side / 64);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (kind) {
      case _DepartmentIconKind.cardiology:
        _drawHeart(canvas, stroke);
        _drawEcg(canvas, stroke);
        break;
      case _DepartmentIconKind.kidney:
        _drawKidneys(canvas, stroke);
        break;
      case _DepartmentIconKind.gastroenterology:
        _drawStomach(canvas, stroke, fill);
        break;
      case _DepartmentIconKind.ent:
        _drawEar(canvas, stroke);
        break;
      case _DepartmentIconKind.eye:
        _drawEye(canvas, stroke, fill);
        break;
      case _DepartmentIconKind.neurology:
        _drawBrain(canvas, stroke);
        break;
      case _DepartmentIconKind.dental:
        _drawTooth(canvas, stroke);
        break;
      case _DepartmentIconKind.orthopedics:
        _drawBone(canvas, stroke);
        break;
      case _DepartmentIconKind.pediatrics:
        _drawBaby(canvas, stroke, fill);
        break;
      case _DepartmentIconKind.gynecology:
        _drawFemaleSymbol(canvas, stroke);
        break;
      case _DepartmentIconKind.dermatology:
        _drawSkinCells(canvas, stroke, fill);
        break;
      case _DepartmentIconKind.pulmonology:
        _drawLungs(canvas, stroke);
        break;
      case _DepartmentIconKind.general:
        _drawHospital(canvas, stroke);
        break;
    }

    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(32, 51)
      ..cubicTo(16, 40, 8, 29, 13, 18)
      ..cubicTo(17, 10, 28, 11, 32, 20)
      ..cubicTo(36, 11, 47, 10, 51, 18)
      ..cubicTo(56, 29, 48, 40, 32, 51);
    canvas.drawPath(path, stroke);
  }

  void _drawEcg(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(15, 31)
      ..lineTo(24, 31)
      ..lineTo(28, 24)
      ..lineTo(34, 39)
      ..lineTo(39, 31)
      ..lineTo(49, 31);
    canvas.drawPath(path, stroke);
  }

  void _drawKidneys(Canvas canvas, Paint stroke) {
    canvas.drawPath(
      Path()
        ..moveTo(27, 13)
        ..cubicTo(12, 15, 10, 34, 18, 47)
        ..cubicTo(24, 57, 37, 50, 32, 39)
        ..cubicTo(27, 30, 35, 20, 27, 13),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(37, 13)
        ..cubicTo(52, 15, 54, 34, 46, 47)
        ..cubicTo(40, 57, 27, 50, 32, 39)
        ..cubicTo(37, 30, 29, 20, 37, 13),
      stroke,
    );
    canvas.drawLine(const Offset(32, 22), const Offset(32, 54), stroke);
  }

  void _drawStomach(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawPath(
      Path()
        ..moveTo(32, 8)
        ..cubicTo(35, 20, 44, 18, 49, 25)
        ..cubicTo(57, 36, 48, 55, 32, 56)
        ..cubicTo(20, 57, 10, 48, 10, 39)
        ..cubicTo(10, 31, 18, 32, 24, 39)
        ..cubicTo(30, 46, 42, 45, 45, 34)
        ..cubicTo(38, 37, 31, 36, 27, 30)
        ..cubicTo(23, 24, 24, 18, 20, 11),
      stroke,
    );
    _drawMedicalCross(canvas, stroke, const Offset(16, 14), 16);
    canvas.drawCircle(const Offset(31, 46), 2.2, fill);
    canvas.drawCircle(const Offset(39, 42), 2.2, fill);
    canvas.drawCircle(const Offset(24, 43), 2.2, fill);
  }

  void _drawEar(Canvas canvas, Paint stroke) {
    canvas.drawPath(
      Path()
        ..moveTo(39, 50)
        ..cubicTo(28, 54, 22, 45, 27, 36)
        ..cubicTo(33, 25, 30, 21, 24, 22)
        ..cubicTo(16, 24, 16, 36, 24, 39)
        ..moveTo(26, 14)
        ..cubicTo(44, 9, 55, 27, 47, 41)
        ..cubicTo(44, 47, 40, 49, 36, 53),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(33, 25)
        ..cubicTo(40, 26, 42, 36, 35, 39),
      stroke,
    );
  }

  void _drawEye(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawPath(
      Path()
        ..moveTo(8, 32)
        ..cubicTo(19, 18, 45, 18, 56, 32)
        ..cubicTo(45, 46, 19, 46, 8, 32),
      stroke,
    );
    canvas.drawCircle(const Offset(32, 32), 10, stroke);
    canvas.drawCircle(const Offset(32, 32), 3.4, fill);
  }

  void _drawBrain(Canvas canvas, Paint stroke) {
    canvas.drawPath(
      Path()
        ..moveTo(31, 52)
        ..cubicTo(17, 53, 10, 42, 14, 32)
        ..cubicTo(7, 22, 18, 12, 28, 16)
        ..cubicTo(33, 7, 47, 11, 47, 23)
        ..cubicTo(56, 27, 54, 44, 44, 47)
        ..cubicTo(42, 53, 35, 55, 31, 52),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(31, 17)
        ..cubicTo(28, 26, 38, 28, 32, 37)
        ..moveTo(20, 31)
        ..cubicTo(28, 29, 29, 42, 40, 39)
        ..moveTo(45, 24)
        ..cubicTo(38, 26, 43, 34, 35, 35),
      stroke,
    );
  }

  void _drawTooth(Canvas canvas, Paint stroke) {
    canvas.drawPath(
      Path()
        ..moveTo(23, 13)
        ..cubicTo(15, 14, 12, 23, 16, 34)
        ..cubicTo(20, 45, 20, 55, 27, 55)
        ..cubicTo(31, 55, 29, 43, 32, 43)
        ..cubicTo(35, 43, 33, 55, 37, 55)
        ..cubicTo(44, 55, 44, 45, 48, 34)
        ..cubicTo(52, 23, 49, 14, 41, 13)
        ..cubicTo(37, 12, 34, 16, 32, 16)
        ..cubicTo(30, 16, 27, 12, 23, 13),
      stroke,
    );
  }

  void _drawBone(Canvas canvas, Paint stroke) {
    canvas.drawPath(
      Path()
        ..moveTo(21, 20)
        ..cubicTo(15, 12, 5, 19, 11, 28)
        ..cubicTo(3, 35, 11, 45, 20, 39)
        ..lineTo(43, 24)
        ..cubicTo(49, 32, 59, 25, 53, 16)
        ..cubicTo(61, 9, 53, -1, 44, 5)
        ..lineTo(21, 20),
      stroke,
    );
  }

  void _drawBaby(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(const Offset(32, 22), 12, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(15, 44)
        ..cubicTo(20, 34, 44, 34, 49, 44)
        ..cubicTo(43, 56, 21, 56, 15, 44),
      stroke,
    );
    canvas.drawCircle(const Offset(27, 22), 1.8, fill);
    canvas.drawCircle(const Offset(37, 22), 1.8, fill);
    canvas.drawPath(
      Path()
        ..moveTo(28, 29)
        ..cubicTo(31, 32, 34, 32, 37, 29),
      stroke,
    );
  }

  void _drawFemaleSymbol(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(32, 24), 15, stroke);
    canvas.drawLine(const Offset(32, 39), const Offset(32, 57), stroke);
    canvas.drawLine(const Offset(22, 49), const Offset(42, 49), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(27, 24)
        ..cubicTo(31, 30, 37, 26, 37, 20),
      stroke,
    );
  }

  void _drawSkinCells(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 16, 40, 32),
        const Radius.circular(15),
      ),
      stroke,
    );
    canvas.drawCircle(const Offset(25, 28), 3, fill);
    canvas.drawCircle(const Offset(39, 35), 3, fill);
    canvas.drawCircle(const Offset(29, 43), 2.2, fill);
    canvas.drawPath(
      Path()
        ..moveTo(16, 53)
        ..cubicTo(25, 48, 39, 58, 48, 52),
      stroke,
    );
  }

  void _drawLungs(Canvas canvas, Paint stroke) {
    canvas.drawLine(const Offset(32, 12), const Offset(32, 35), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(31, 28)
        ..cubicTo(23, 18, 14, 19, 13, 34)
        ..cubicTo(12, 48, 19, 55, 29, 49)
        ..cubicTo(31, 42, 31, 35, 31, 28),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(33, 28)
        ..cubicTo(41, 18, 50, 19, 51, 34)
        ..cubicTo(52, 48, 45, 55, 35, 49)
        ..cubicTo(33, 42, 33, 35, 33, 28),
      stroke,
    );
  }

  void _drawHospital(Canvas canvas, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 17, 36, 34),
        const Radius.circular(5),
      ),
      stroke,
    );
    _drawMedicalCross(canvas, stroke, const Offset(32, 30), 18);
  }

  void _drawMedicalCross(
    Canvas canvas,
    Paint stroke,
    Offset center,
    double size,
  ) {
    final half = size / 2;
    final arm = size / 5;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - half,
        center.dy - arm,
        center.dx + half,
        center.dy + arm,
      ),
      const Radius.circular(1.5),
    );
    final vertical = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        center.dx - arm,
        center.dy - half,
        center.dx + arm,
        center.dy + half,
      ),
      const Radius.circular(1.5),
    );
    canvas
      ..drawRRect(rect, stroke)
      ..drawRRect(vertical, stroke);
  }

  @override
  bool shouldRepaint(covariant _DepartmentIconPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}
