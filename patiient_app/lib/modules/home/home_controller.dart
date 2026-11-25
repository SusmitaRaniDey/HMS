import 'package:get/get.dart';

import '../../data/models/appointment_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/providers/appointment_provider.dart';
import '../../data/providers/booking_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';

class HomeController extends GetxController {
  final AppointmentProvider _appointmentProvider = AppointmentProvider();
  final BookingProvider _bookingProvider = BookingProvider();
  final StorageService _storageService = Get.find<StorageService>();

  // Observables
  final isLoading = false.obs;
  final upcomingAppointments = <AppointmentModel>[].obs;
  final upcomingBookings = <BookingModel>[].obs;
  final Rx<PatientModel?> currentPatient = Rx<PatientModel?>(null);
  final doctorProfilePics = <int, String>{}.obs;
  final doctorDepartments = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  // Load all dashboard data
  Future<void> loadDashboardData() async {
    loadPatientData();
    await Future.wait([loadUpcomingAppointments(), loadUpcomingBookings()]);
  }

  // Load patient data from storage
  void loadPatientData() {
    final patientData = _storageService.getPatient();
    if (patientData != null) {
      currentPatient.value = PatientModel.fromJson(patientData);
    }
  }

  // Load upcoming appointments
  Future<void> loadUpcomingAppointments() async {
    try {
      isLoading.value = true;
      final appointments = await _appointmentProvider.getUpcomingAppointments();
      upcomingAppointments.value = appointments.take(3).toList();
      await _loadDoctorProfilePics();
    } catch (e) {
      Get.log('Error loading upcoming appointments: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadDoctorProfilePics() async {
    try {
      final result = await _appointmentProvider.getAllDoctors(limit: 100);
      final List<dynamic> data = result['data'] as List;
      final departments = <String>{};
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int?;
        final pic = (map['profilePic'] ?? map['profile_pic']) as String?;
        final specialty = map['specialty']?.toString().trim();
        if (id != null && pic != null) {
          doctorProfilePics[id] = pic;
        }
        if (specialty != null && specialty.isNotEmpty) {
          departments.add(specialty);
        }
      }
      doctorDepartments.value = departments.take(12).toList();
    } catch (_) {
      // Profile pics are optional — silently ignore failures
    }
  }

  // Load upcoming bookings
  Future<void> loadUpcomingBookings() async {
    try {
      final bookings = await _bookingProvider.getUpcomingBookings();
      upcomingBookings.value = bookings.take(3).toList();
    } catch (e) {
      Get.log('Error loading upcoming bookings: $e', isError: true);
      // Don't show error snackbar on dashboard - just log
    }
  }

  // Refresh dashboard
  Future<void> refreshDashboard() async {
    await loadDashboardData();
    Helpers.showSuccessSnackbar('Refreshed', 'Dashboard updated');
  }

  // Get greeting based on time
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Get patient name
  String getPatientName() {
    return currentPatient.value?.name ?? 'Guest';
  }
}
