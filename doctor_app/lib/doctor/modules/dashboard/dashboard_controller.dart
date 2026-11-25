import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  final todayAppointments = <AppointmentModel>[].obs;
  final upcomingAppointments = <AppointmentModel>[].obs;
  final nextAppointments = <AppointmentModel>[].obs;

  // Error flags (true when the last fetch for that section failed) so the
  // UI can distinguish "failed to load" from "genuinely zero results".
  final pendingError = false.obs;
  final confirmedError = false.obs;
  final todayError = false.obs;
  final upcomingError = false.obs;

  Timer? _nextAppointmentTimer;

  @override
  void onInit() {
    super.onInit();
    loadDoctorData();
    loadDashboardData();
    _nextAppointmentTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => updateNextAppointments(),
    );
  }

  @override
  void onClose() {
    _nextAppointmentTimer?.cancel();
    super.onClose();
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
        loadUpcomingAppointments(),
      ]);
      updateNextAppointments();
    } catch (e) {
      _logger.e('Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load pending appointments (VIEW-ONLY)
  Future<void> loadPendingAppointments() async {
    try {
      pendingError.value = false;
      final appointments = await _provider.getPendingAppointments();
      pendingAppointments.value = appointments.take(5).toList();
      pendingCount.value = appointments.length;
    } catch (e) {
      _logger.e('Error loading pending: $e');
      pendingError.value = true;
    }
  }

  // Load confirmed appointments (VIEW-ONLY)
  Future<void> loadConfirmedAppointments() async {
    try {
      confirmedError.value = false;
      final appointments = await _provider.getConfirmedAppointments();
      confirmedAppointments.value = _sortAppointmentsByTime(appointments)
          .take(5)
          .toList();
      confirmedCount.value = appointments.length;
    } catch (e) {
      _logger.e('Error loading confirmed: $e');
      confirmedError.value = true;
    }
  }

  // Load today's appointments (VIEW-ONLY)
  Future<void> loadTodayAppointments() async {
    try {
      todayError.value = false;
      final appointments = await _provider.getTodayAppointments();
      todayAppointments.value = _sortAppointmentsByTime(appointments);
      todayCount.value = appointments.length;
    } catch (e) {
      _logger.e('Error loading today: $e');
      todayError.value = true;
    }
  }

  // Load future appointments for the top next appointments list.
  Future<void> loadUpcomingAppointments() async {
    try {
      upcomingError.value = false;
      final appointments = await _provider.getUpcomingAppointments();
      upcomingAppointments.value = _sortAppointmentsByTime(appointments);
    } catch (e) {
      _logger.e('Error loading upcoming: $e');
      upcomingError.value = true;
    }
  }

  void updateNextAppointments() {
    final now = DateTime.now();
    final candidates = <int, AppointmentModel>{};

    for (final appointment in [
      ...upcomingAppointments,
      ...todayAppointments,
      ...confirmedAppointments,
    ]) {
      final endTime = appointmentEndDateTime(appointment);
      if (_isConfirmedAppointment(appointment) &&
          (endTime == null || endTime.isAfter(now))) {
        candidates[appointment.id] = appointment;
      }
    }

    final sorted = _sortAppointmentsByTime(candidates.values.toList());
    nextAppointments.value = sorted;
  }

  bool _isConfirmedAppointment(AppointmentModel appointment) {
    final status = appointment.status.toLowerCase().trim();
    return status == 'confirmed' || status == 'approved' || status == 'accepted';
  }

  List<AppointmentModel> _sortAppointmentsByTime(
    List<AppointmentModel> appointments,
  ) {
    final sorted = [...appointments];
    sorted.sort((a, b) {
      final aTime = appointmentStartDateTime(a);
      final bTime = appointmentStartDateTime(b);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });
    return sorted;
  }

  DateTime? appointmentStartDateTime(AppointmentModel appointment) {
    if (appointment.startTime != null && appointment.startTime!.isNotEmpty) {
      try {
        return DateTime.parse(appointment.startTime!).toLocal();
      } catch (_) {}
    }

    final date = _parseAppointmentDate(appointment.date);
    if (date == null) return null;

    final time = _parseTimeFromSlot(appointment.timeSlot, useEndTime: false);
    if (time == null) return date;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  DateTime? appointmentEndDateTime(AppointmentModel appointment) {
    final start = appointmentStartDateTime(appointment);
    if (start == null) return null;

    final date = _parseAppointmentDate(appointment.date);
    final endTime = _parseTimeFromSlot(appointment.timeSlot, useEndTime: true);

    if (date != null && endTime != null) {
      var end = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }
      return end;
    }

    return start.add(const Duration(minutes: 30));
  }

  String formatAppointmentTime(AppointmentModel appointment) {
    final start = appointmentStartDateTime(appointment);
    if (start == null) return appointment.timeSlot ?? 'N/A';
    return DateFormat('hh:mm a').format(start);
  }

  String formatAppointmentDay(AppointmentModel appointment) {
    final start = appointmentStartDateTime(appointment);
    if (start == null) return Helpers.getRelativeDate(appointment.date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(start.year, start.month, start.day);

    if (appointmentDay == today) return 'Today';
    if (appointmentDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    }
    return DateFormat('dd MMM, EEEE').format(start);
  }

  DateTime? _parseAppointmentDate(String value) {
    if (value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      for (final pattern in ['dd MMM yyyy', 'MM/dd/yyyy', 'dd/MM/yyyy']) {
        try {
          return DateFormat(pattern).parse(value);
        } catch (_) {}
      }
    }
    return null;
  }

  DateTime? _parseTimeFromSlot(String? slot, {required bool useEndTime}) {
    if (slot == null || slot.trim().isEmpty) return null;

    final parts = slot.split(RegExp(r'\s*(?:-|to)\s*'));
    final raw = useEndTime && parts.length > 1 ? parts.last : parts.first;
    final timeText = raw.trim().toUpperCase();

    for (final pattern in ['hh:mm a', 'h:mm a', 'HH:mm', 'H:mm']) {
      try {
        return DateFormat(pattern).parseStrict(timeText);
      } catch (_) {}
    }

    return null;
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
    return currentDoctor.value?.name ?? 'Doctor';
  }
}
