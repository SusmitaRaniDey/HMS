import 'package:get/get.dart';
import '../config/api_endpoints.dart';
import '../models/diagnostic_booking_model.dart';
import '../models/doctor_model.dart';
import '../services/api_services.dart';

class DashboardController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;

  // ── Activity Overview Stats ────────────────────────────────────────────────
  final totalPatients = 0.obs;
  final totalDoctors = 0.obs;
  final totalAppointments = 0.obs;
  final totalDiagnostics = 0.obs;

  // ── Popular Doctor List ────────────────────────────────────────────────────
  final popularDoctors = <DoctorModel>[].obs;

  // ── Patient Visit By Diagnostic (doughnut chart) ──────────────────────────
  // Map of diagnosticCategory → count
  final diagnosticCategoryData = <String, int>{}.obs;

  // ── Appointment Survey (line chart, last 7 days) ───────────────────────────
  // [{day: 'Mon', confirmed: 12.0, pending: 8.0}, ...]
  final appointmentTrendData = <Map<String, dynamic>>[].obs;

  // ── Diagnostic Booking List (table, last 5) ───────────────────────────────
  final recentDiagnosticBookings = <DiagnosticBookingModel>[].obs;

  // ── Average Appointment By Department/Specialty (bar chart) ──────────────
  final deptAppointmentData = <String, int>{}.obs;

  // ── Staff By Role (bar chart) ─────────────────────────────────────────────
  final staffByRole = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        _loadDoctorsData(),
        _loadPatientsCount(),
        _loadAppointmentsData(),
        _loadDiagnosticBookingData(),
        _loadStaffData(),
      ]);
    } catch (e) {
      print('Dashboard load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadDoctorsData() async {
    try {
      final res = await _apiService.get(ApiEndpoints.DOCTORS_WITH_APPOINTMENTS);
      if (res.data != null) {
        final list = res.data as List;
        final doctors = list.map((j) => DoctorModel.fromJson(j)).toList();
        totalDoctors.value = doctors.length;
        // Sort by appointmentsCount descending, show top 5
        doctors.sort(
          (a, b) =>
              (b.appointmentsCount ?? 0).compareTo(a.appointmentsCount ?? 0),
        );
        popularDoctors.value = doctors.take(5).toList();
      }
    } catch (e) {
      print('Error loading doctors: $e');
    }
  }

  Future<void> _loadPatientsCount() async {
    try {
      final res = await _apiService.get(ApiEndpoints.USERS);
      totalPatients.value = (res.data as List).length;
    } catch (e) {
      print('Error loading patients: $e');
    }
  }

  Future<void> _loadAppointmentsData() async {
    try {
      final res = await _apiService.get(
        '${ApiEndpoints.APPOINTMENTS}?limit=1000',
      );
      final data =
          res.data is Map && res.data.containsKey('data')
              ? res.data['data'] as List
              : res.data as List;
      totalAppointments.value = data.length;
      _buildAppointmentTrend(data);
      _buildDeptAppointmentData(data);
    } catch (e) {
      print('Error loading appointments: $e');
      _buildMockTrendData();
    }
  }

  void _buildDeptAppointmentData(List data) {
    final map = <String, int>{};
    for (final item in data) {
      final specialty =
          (item['doctor']?['specialty'] as String?)?.trim();
      final key = (specialty != null && specialty.isNotEmpty)
          ? specialty
          : 'General';
      map[key] = (map[key] ?? 0) + 1;
    }
    deptAppointmentData.value = map;
  }

  void _buildAppointmentTrend(List data) {
    final now = DateTime.now();
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final trend = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final weekdayName = dayNames[day.weekday - 1];

      final confirmed = data
          .where(
            (a) =>
                a['status'] == 'confirmed' &&
                (a['date'] ?? '').toString().startsWith(dayStr),
          )
          .length;
      final pending = data
          .where(
            (a) =>
                a['status'] == 'pending' &&
                (a['date'] ?? '').toString().startsWith(dayStr),
          )
          .length;

      trend.add({
        'day': weekdayName,
        'confirmed': confirmed.toDouble(),
        'pending': pending.toDouble(),
      });
    }
    appointmentTrendData.value = trend;
  }

  void _buildMockTrendData() {
    // TODO: Replace with real appointment trend endpoint when available
    appointmentTrendData.value = [
      {'day': 'Mon', 'confirmed': 12.0, 'pending': 8.0},
      {'day': 'Tue', 'confirmed': 19.0, 'pending': 5.0},
      {'day': 'Wed', 'confirmed': 15.0, 'pending': 11.0},
      {'day': 'Thu', 'confirmed': 22.0, 'pending': 7.0},
      {'day': 'Fri', 'confirmed': 18.0, 'pending': 9.0},
      {'day': 'Sat', 'confirmed': 25.0, 'pending': 4.0},
      {'day': 'Sun', 'confirmed': 10.0, 'pending': 6.0},
    ];
  }

  Future<void> _loadStaffData() async {
    try {
      final res = await _apiService.get(ApiEndpoints.STAFF);
      if (res.data != null) {
        final map = <String, int>{};
        for (final item in res.data as List) {
          final raw = (item['role'] as String?)?.trim() ?? 'admin';
          final label = raw
              .split('_')
              .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' ');
          map[label] = (map[label] ?? 0) + 1;
        }
        staffByRole.value = map;
      }
    } catch (e) {
      print('Error loading staff data: $e');
    }
  }

  Future<void> _loadDiagnosticBookingData() async {
    try {
      final res = await _apiService.get(
        '${ApiEndpoints.DIAGNOSTIC_BOOKINGS}?limit=1000',
      );
      final data =
          res.data is Map && res.data.containsKey('data')
              ? res.data['data'] as List
              : res.data as List;

      totalDiagnostics.value = data.length;

      final allBookings =
          data.map((j) => DiagnosticBookingModel.fromJson(j)).toList();
      allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      recentDiagnosticBookings.value = allBookings.take(5).toList();

      // Build category breakdown map
      final categoryMap = <String, int>{};
      for (final b in allBookings) {
        final cat =
            b.diagnosticCategory.isNotEmpty ? b.diagnosticCategory : 'Other';
        categoryMap[cat] = (categoryMap[cat] ?? 0) + 1;
      }

      // Fall back to mock if no real data
      diagnosticCategoryData.value =
          categoryMap.isEmpty
              ? {'Blood Test': 40, 'X-Ray': 30, 'MRI': 20, 'ECG': 10}
              : categoryMap;
    } catch (e) {
      print('Error loading diagnostic data: $e');
      // TODO: Remove mock when real API is stable
      diagnosticCategoryData.value = {
        'Blood Test': 40,
        'X-Ray': 30,
        'MRI': 20,
        'ECG': 10,
      };
    }
  }
}
