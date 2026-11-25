import 'dart:math';
import 'package:admin_panel_web_app/services/storage_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/dashboard_controller.dart';
import '../../models/diagnostic_booking_model.dart';
import '../../models/doctor_model.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/empty_state_widget.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kOrange = Color(0xFF0F766E);
const _kOrange1 = Color(0xFFCCFBF1);
const _kOrangeLight = Color(0xFFF0FDFA);
const _kNavy = Color(0xFF0B132B);
const _kGreen = Color(0xFF10B981);
const _kRed = Color(0xFFF43F5E);
const _kYellow = Color(0xFFF59E0B);
const _kPurple = Color(0xFF8B5CF6);
const _kBlue = Color(0xFF0EA5E9);
const _kBg = Color(0xFFF6F8FB);
const _kTextPrimary = Color(0xFF172033);
const _kTextSecondary = Color(0xFF697386);
const _kBorder = Color(0xFFE7EAF0);
const _kWhite = Colors.white;

const _kChartColors = [_kOrange, _kBlue, _kYellow, _kPurple, _kGreen];

BoxDecoration _card({Color bg = _kWhite}) => BoxDecoration(
  color: bg,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: _kBorder),
  boxShadow: const [
    BoxShadow(color: Color(0x0D0B132B), blurRadius: 28, offset: Offset(0, 10)),
  ],
);

// ─── Main Screen ───────────────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // var admin = StorageService().getAdmin();
    // print('Admin from storage: $admin');

    final ctrl = Get.find<DashboardController>();
    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/dashboard'),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: Obx(() {
                    if (ctrl.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: _kOrange),
                      );
                    }
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRow1(ctrl),
                          SizedBox(height: 20.h),
                          _buildAppointmentSurvey(ctrl),
                          SizedBox(height: 20.h),
                          _buildRow3(ctrl),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Row 1: Activity | Doughnut | Popular Doctors ────────────────────────────
  Widget _buildRow1(DashboardController ctrl) {
    return SizedBox(
      height: 380.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 38, child: _ActivityOverview(ctrl: ctrl)),

          SizedBox(width: 16.w),
          Expanded(flex: 30, child: _PatientVisitChart(ctrl: ctrl)),

          SizedBox(width: 16.w),
          Expanded(flex: 30, child: _PopularDoctorList(ctrl: ctrl)),
        ],
      ),
    );
  }

  // ─── Row 2: Appointment Survey (full width) ────────────────────────────────
  Widget _buildAppointmentSurvey(DashboardController ctrl) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Appointment Survey',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: _kGreen, label: 'Confirmed Appointments'),
                  SizedBox(width: 20.w),
                  _LegendDot(color: _kYellow, label: 'Pending Appointments'),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Obx(() {
            final data = ctrl.appointmentTrendData;
            return SizedBox(
              height: 200.h,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(
                  data: data,
                  confirmedColor: _kGreen,
                  pendingColor: _kYellow,
                  isEmpty: data.isEmpty,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Row 3: Table | Right Column ─────────────────────────────────────────────
  Widget _buildRow3(DashboardController ctrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _DiagnosticBookingList(ctrl: ctrl)),
        SizedBox(width: 16.w),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _AvgPatientByDept(ctrl: ctrl),
              SizedBox(height: 16.h),
              _EmployeesByDept(ctrl: ctrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final adminData = Get.find<StorageService>().getAdmin();
    final adminName = adminData?['name'] as String? ?? 'Admin';

    return Container(
      height: 68.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF162544)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x260B132B),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          // Logo + brand
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: _kWhite,
                  size: 17.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'HealthGrid',
                style: TextStyle(
                  color: _kWhite,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(width: 28.w),
          // Page title
          Text(
            'Dashboard',
            style: TextStyle(
              color: _kWhite,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 20.w),
          // Search bar
          /* Container(
            width: 210.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F8),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                SizedBox(width: 12.w),
                Icon(
                  Icons.search_rounded,
                  color: Colors.grey[400],
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Search here...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ), */
          const Spacer(),
          // Notification bell + badge
          /* Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 22.sp,
                color: _kTextSecondary,
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: _kWhite, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: _kWhite,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ), */
          SizedBox(width: 20.w),
          // Avatar + info
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: _kWhite.withValues(alpha: 0.14),
                child: Icon(Icons.person, color: _kWhite, size: 17.sp),
              ),
              SizedBox(width: 8.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adminName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: _kWhite,
                    ),
                  ),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFFB8C2D8),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFFB8C2D8),
                size: 16.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Activity Overview ─────────────────────────────────────────────────────────
class _ActivityOverview extends StatelessWidget {
  final DashboardController ctrl;
  const _ActivityOverview({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              Icon(Icons.more_horiz, color: _kTextSecondary, size: 18.sp),
            ],
          ),
          SizedBox(height: 14.h),
          Obx(
            () => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Total Patient',
                        value: ctrl.totalPatients.value.toString(),
                        color: _kOrange,
                        icon: Icons.people_alt_rounded,
                        onTap: () => Get.toNamed('/users'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Total Doctor',
                        value: ctrl.totalDoctors.value.toString(),
                        color: _kBlue,
                        icon: Icons.medical_services_rounded,
                        onTap: () => Get.toNamed('/doctors'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Appointments',
                        value: ctrl.totalAppointments.value.toString(),
                        color: _kPurple,
                        icon: Icons.calendar_month_rounded,
                        onTap: () => Get.toNamed('/appointments'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Diagnostics',
                        value: ctrl.totalDiagnostics.value.toString(),
                        color: _kRed,
                        icon: Icons.biotech_rounded,
                        onTap: () => Get.toNamed('/diagnostics'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(icon, color: _kWhite, size: 16.sp),
                  ),
                  Icon(Icons.more_horiz, color: _kTextSecondary, size: 14.sp),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(fontSize: 10.sp, color: _kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Patient Visit By Diagnostic ──────────────────────────────────────────────
class _PatientVisitChart extends StatelessWidget {
  final DashboardController ctrl;
  const _PatientVisitChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patient Visit By\nDiagnostic',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  height: 1.4,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorder),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  children: [
                    Text(
                      'Weekly',
                      style: TextStyle(fontSize: 11.sp, color: _kTextSecondary),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14.sp,
                      color: _kTextSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Obx(() {
              final data = ctrl.diagnosticCategoryData;
              if (data.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.science_rounded,
                  title: 'No Diagnostic Data',
                  subtitle: 'Diagnostic categories will display once bookings are recorded',
                  iconColor: _kRed,
                  height: 180.h,
                );
              }
              return Row(
                children: [
                  // Doughnut chart
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(
                          painter: _DoughnutPainter(
                            data: data.entries.toList(),
                            colors: _kChartColors,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: () {
                        final total = data.values.fold(0, (a, b) => a + b);
                        final entries = data.entries.toList();
                        return List.generate(entries.length, (i) {
                          final pct = total > 0
                              ? (entries[i].value / total * 100).round()
                              : 0;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 9.w,
                                  height: 9.w,
                                  decoration: BoxDecoration(
                                    color:
                                        _kChartColors[i % _kChartColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    entries[i].key,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: _kTextSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: _kTextPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      }(),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Popular Doctor List ───────────────────────────────────────────────────────
class _PopularDoctorList extends StatelessWidget {
  final DashboardController ctrl;
  const _PopularDoctorList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _card(bg: const Color.fromARGB(255, 255, 255, 255)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Doctor List',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
              Icon(Icons.more_horiz, color: _kTextSecondary, size: 18.sp),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Doctor Name',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color.fromARGB(255, 174, 10, 10),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: _kOrange,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Divider(color: _kOrange1, height: 1),
          SizedBox(height: 6.h),
          Obx(() {
            final docs = ctrl.popularDoctors;
            if (docs.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: EmptyStateWidget(
                  icon: Icons.medical_services_rounded,
                  title: 'No Popular Doctors Yet',
                  subtitle: 'Top doctors will appear here based on appointment activity',
                  iconColor: _kBlue,
                  height: 160.h,
                ),
              );
            }
            return Column(
              children: docs
                  .map(
                    (doc) => Column(
                      children: [
                        _DoctorRow(doc: doc),
                        Divider(color: _kOrange1, height: 0.1),
                      ],
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _DoctorRow extends StatelessWidget {
  final DoctorModel doc;
  const _DoctorRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isAvailable = doc.status == 'active';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15.r,
            backgroundColor: _kOrangeLight.withValues(alpha: 0.25),
            backgroundImage: doc.profilePic != null
                ? NetworkImage(doc.profilePic!)
                : null,
            child: doc.profilePic == null
                ? Text(
                    doc.name[0].toUpperCase(),
                    style: TextStyle(
                      color: _kOrangeLight,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              doc.name,
              style: TextStyle(
                color:
                    _kNavy, //const Color.fromARGB(255, 14, 14, 15),//_kWhite,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: isAvailable
                  ? _kGreen.withValues(alpha: 0.18)
                  : _kRed.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              isAvailable ? 'Available' : 'Absent',
              style: TextStyle(
                color: isAvailable ? _kGreen : _kRed,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diagnostic Booking List ───────────────────────────────────────────────────
class _DiagnosticBookingList extends StatelessWidget {
  final DashboardController ctrl;
  const _DiagnosticBookingList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diagnostic Booking List',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed('/diagnostic-bookings'),
                child: Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _kOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Header row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                _TH('Name', flex: 3),
                _TH('Date', flex: 2),
                _TH('Test Type', flex: 3),
                _TH('Status', flex: 2),
                _TH('Actions', flex: 1),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          // Body rows
          Obx(() {
            final bookings = ctrl.recentDiagnosticBookings;
            if (bookings.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 30.h),
                child: EmptyStateWidget(
                  icon: Icons.biotech_rounded,
                  title: 'No Diagnostic Bookings',
                  subtitle: 'New bookings will appear in this list as patients request tests',
                  iconColor: _kOrange,
                  height: 200.h,
                ),
              );
            }
            return Column(
              children: bookings.map((b) => _BookingRow(booking: b)).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: _kTextSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final DiagnosticBookingModel booking;
  const _BookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        statusColor = _kGreen;
        statusBg = _kGreen.withValues(alpha: 0.12);
        break;
      case 'cancelled':
        statusColor = _kRed;
        statusBg = _kRed.withValues(alpha: 0.12);
        break;
      default:
        statusColor = _kYellow;
        statusBg = _kYellow.withValues(alpha: 0.12);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13.r,
                  backgroundColor: _kOrange.withValues(alpha: 0.15),
                  child: Text(
                    booking.patientName.isNotEmpty
                        ? booking.patientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: _kOrange,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    booking.patientName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              booking.scheduleDate.length >= 10
                  ? booking.scheduleDate.substring(0, 10)
                  : booking.scheduleDate,
              style: TextStyle(fontSize: 11.sp, color: _kTextSecondary),
            ),
          ),
          // Test Type
          Expanded(
            flex: 3,
            child: Text(
              booking.diagnosticCategory.isNotEmpty
                  ? booking.diagnosticCategory
                  : 'General',
              style: TextStyle(fontSize: 11.sp, color: _kTextSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status badge
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  booking.status[0].toUpperCase() + booking.status.substring(1),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 15.sp, color: _kTextSecondary),
                SizedBox(width: 8.w),
                Icon(Icons.delete_outline_rounded, size: 15.sp, color: _kRed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Average Patient By Department ────────────────────────────────────────────
class _AvgPatientByDept extends StatelessWidget {
  final DashboardController ctrl;
  const _AvgPatientByDept({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average Appointment',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  Text(
                    'By Department',
                    style: TextStyle(fontSize: 11.sp, color: _kTextSecondary),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorder),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  children: [
                    Text(
                      'Weekly',
                      style: TextStyle(fontSize: 10.sp, color: _kTextSecondary),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 12.sp,
                      color: _kTextSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Obx(() {
            final data = ctrl.deptAppointmentData;
            if (data.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.bar_chart_rounded,
                title: 'No Department Data',
                subtitle: 'Appointment averages by department will display once available',
                iconColor: _kPurple,
                height: 160.h,
              );
            }
            return _DepartmentBarChart(data: data.entries.toList());
          }),
        ],
      ),
    );
  }
}

// ─── Employees by Department ───────────────────────────────────────────────────
class _DepartmentBarChart extends StatelessWidget {
  const _DepartmentBarChart({required this.data});

  final List<MapEntry<String, int>> data;

  static const colors = [
    Color(0xFF9AD83D),
    Color(0xFF50D1A0),
    Color(0xFF47C6D4),
    Color(0xFF36A9E1),
    Color(0xFF4388DC),
  ];

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      1,
      (current, item) => max(current, item.value),
    );
    final chartHeight = 112.h;

    return SizedBox(
      height: chartHeight + 34.h,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 28.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (_) => const Divider(height: 1, color: Color(0xFFEDF0F4)),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                final entry = data[index];
                final color = colors[index % colors.length];
                final barHeight = max(
                  20.h,
                  entry.value / maxValue * (chartHeight - 12.h),
                );
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: chartHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: 38.w,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(5.r),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: -16.h,
                                child: Container(
                                  width: 34.w,
                                  height: 34.w,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: color, width: 4),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A0F172A),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: FittedBox(
                                    child: Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _kTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeesByDept extends StatelessWidget {
  final DashboardController ctrl;
  const _EmployeesByDept({required this.ctrl});

  static const _staffColors = [_kOrange, _kBlue, _kGreen, _kPurple, _kYellow];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Employees',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Number of staffs according to role',
                  style: TextStyle(fontSize: 10.sp, color: _kTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Obx(() {
            final data = ctrl.staffByRole;
            if (data.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.people_alt_rounded,
                title: 'No Staff Data',
                subtitle: 'Staff information by role will appear once employees are added',
                iconColor: _kOrange,
                height: 160.h,
              );
            }
            return _BarChart(
              data: data.entries.toList(),
              chartHeight: 80.h,
              highlightMax: false,
              barColorFn: (i, isMax) => _staffColors[i % _staffColors.length],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Bar Chart Widget ──────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<MapEntry<String, int>> data;
  final double chartHeight;
  final bool highlightMax;
  final Color Function(int index, bool isMax) barColorFn;

  const _BarChart({
    required this.data,
    required this.chartHeight,
    required this.highlightMax,
    required this.barColorFn,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: chartHeight + 45.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          final entry = data[i];
          final isMax = entry.value == maxVal.toInt();
          final barH = maxVal > 0 ? (entry.value / maxVal * chartHeight) : 4.0;
          final color = barColorFn(i, isMax);
          final label = entry.key.length > 5
              ? entry.key.substring(0, 5)
              : entry.key;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    width: double.infinity,
                    height: barH.clamp(4.0, chartHeight),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4.r),
                        topRight: Radius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  FittedBox(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 9.sp, color: _kTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Legend Dot ────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20.w,
          height: 3.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: _kTextSecondary),
        ),
      ],
    );
  }
}

// ─── Doughnut Chart Painter ────────────────────────────────────────────────────
class _DoughnutPainter extends CustomPainter {
  final List<MapEntry<String, int>> data;
  final List<Color> colors;
  const _DoughnutPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0, (sum, e) => sum + e.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.38;
    final arcRadius = radius - strokeWidth / 2;

    double startAngle = -pi / 2;
    const gap = 0.05;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * pi;
      final actualSweep = (sweepAngle - gap).clamp(0.01, sweepAngle);

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        actualSweep,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Line Chart Painter ────────────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color confirmedColor;
  final Color pendingColor;
  final bool isEmpty;

  const _LineChartPainter({
    required this.data,
    required this.confirmedColor,
    required this.pendingColor,
    this.isEmpty = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const paddingLeft = 40.0;
    final paddingBottom = size.height * 0.12;
    final paddingTop = size.height * 0.05;
    final chartWidth = size.width - paddingLeft;
    final chartHeight = size.height - paddingBottom - paddingTop;

    // Determine max value
    late double maxValue;
    if (isEmpty || data.isEmpty) {
      maxValue = 100.0;
    } else if (data.length < 2) {
      maxValue = 100.0;
    } else {
      final allVals = data.expand((d) => [
        (d['confirmed'] as double? ?? 0.0),
        (d['pending'] as double? ?? 0.0),
      ]);
      maxValue = allVals.fold(0.0, (a, b) => a > b ? a : b);
      if (maxValue <= 0) maxValue = 100.0;
    }

    // Grid lines and Y-axis labels
    final gridPaint = Paint()
      ..color = _kBorder
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + chartHeight - (i / 4) * chartHeight;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), gridPaint);
      // Y-axis labels
      final tp = TextPainter(
        text: TextSpan(
          text: '${((i / 4) * maxValue).round()}',
          style: const TextStyle(color: _kTextSecondary, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Draw axes
    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight),
      Offset(size.width, paddingTop + chartHeight),
      Paint()..color = _kBorder..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, paddingTop + chartHeight),
      Paint()..color = _kBorder..strokeWidth = 1.5,
    );

    // If empty, show message and return
    if (isEmpty || data.isEmpty || data.length < 2) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Awaiting appointment data...',
          style: TextStyle(color: _kTextSecondary, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          size.width / 2 - tp.width / 2,
          paddingTop + chartHeight / 2 - tp.height / 2,
        ),
      );
      return;
    }

    Offset getSeriesPoint(int idx, String key) {
      final x = paddingLeft + (idx / (data.length - 1)) * chartWidth;
      final val = data[idx][key] as double? ?? 0.0;
      final y = paddingTop + chartHeight - (val / maxValue) * chartHeight;
      return Offset(x, y);
    }

    void drawSeries(String key, Color lineColor) {
      final points = List.generate(data.length, (i) => getSeriesPoint(i, key));

      // Area fill
      final fillPath = Path()
        ..moveTo(points.first.dx, paddingTop + chartHeight);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath
        ..lineTo(points.last.dx, paddingTop + chartHeight)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()..color = lineColor.withValues(alpha: 0.10),
      );

      // Line
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Dots
      for (final p in points) {
        canvas.drawCircle(p, 3.5, Paint()..color = lineColor);
        canvas.drawCircle(
          p,
          3.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    drawSeries('pending', pendingColor);
    drawSeries('confirmed', confirmedColor);

    // X-axis day labels
    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + (i / (data.length - 1)) * chartWidth;
      final tp = TextPainter(
        text: TextSpan(
          text: data[i]['day'] as String? ?? '',
          style: const TextStyle(color: _kTextSecondary, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
