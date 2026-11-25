import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../data/models/appointment_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/providers/appointment_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';

class DashboardController extends GetxController {
  final AppointmentProvider _provider = AppointmentProvider();
  final StorageService _storage = Get.find<StorageService>(tag: 'doctor');
  final Logger _logger = Logger();

  // Observables
  final isLoading = false.obs;
  final Rx<DoctorModel?> currentDoctor = Rx<DoctorModel?>(null);

  // Statistics (VIEW-ONLY)
  final pendingCount = 0.obs;
  final confirmedCount = 0.obs;
  final todayCount = 0.obs;

  // Lists (VIEW-ONLY)
  final pendingAppointments = <AppointmentModel>[].obs;
  final confirmedAppointments = <AppointmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDoctorData();
    loadDashboardData();
  }

  // Load doctor data
  void loadDoctorData() {
    final doctorData = _storage.getDoctor();
    if (doctorData != null) {
      currentDoctor.value = DoctorModel.fromJson(doctorData);
    }
  }

  // Load all dashboard data (VIEW-ONLY)
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        loadPendingAppointments(),
        loadConfirmedAppointments(),
        loadTodayAppointments(),
      ]);
    } catch (e) {
      _logger.e('Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load pending appointments (VIEW-ONLY)
  Future<void> loadPendingAppointments() async {
    try {
      final appointments = await _provider.getPendingAppointments();
      pendingAppointments.value = appointments.take(5).toList();
      pendingCount.value = appointments.length;
    } catch (e) {
      _logger.e('Error loading pending: $e');
    }
  }

  // Load confirmed appointments (VIEW-ONLY)
  Future<void> loadConfirmedAppointments() async {
    try {
      final appointments = await _provider.getConfirmedAppointments();
      confirmedAppointments.value = appointments.take(5).toList();
      confirmedCount.value = appointments.length;
    } catch (e) {
      _logger.e('Error loading confirmed: $e');
    }
  }

  // Load today's appointments (VIEW-ONLY)
  Future<void> loadTodayAppointments() async {
    try {
      final appointments = await _provider.getTodayAppointments();
      todayCount.value = appointments.length;
    } catch (e) {
      _logger.e('Error loading today: $e');
    }
  }

  // Refresh dashboard
  Future<void> refreshDashboard() async {
    await loadDashboardData();
    Helpers.showSuccessSnackbar('Refreshed', 'Dashboard updated');
  }

  // Get greeting
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

  // Get doctor name
  String getDoctorName() {
    return currentDoctor.value?.name?? 'Doctor';
  }
}