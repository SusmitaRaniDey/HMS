import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../data/models/appointment_model.dart';
import '../../data/providers/appointment_provider.dart';
import '../../utils/helpers.dart';

class DoctorAppointmentsController extends GetxController {
  final AppointmentProvider _provider = AppointmentProvider();

  // Observables
  final isLoading = false.obs;
  final appointments = <AppointmentModel>[].obs;
  final filteredAppointments = <AppointmentModel>[].obs;
  final selectedFilter = 'All'.obs;

  final List<String> filters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  // Load all appointments (VIEW-ONLY)
  Future<void> loadAppointments() async {
    try {
      isLoading.value = true;
      final result = await _provider.getAppointments();
      final rawData = result['data'];
      final List<dynamic> data = rawData is List ? rawData : [];
      appointments.value = data
          .whereType<Map>()
          .map((json) => AppointmentModel.fromJson(json.cast<String, dynamic>()))
          .toList();
      applyFilter(selectedFilter.value);
    } catch (e) {
      debugPrint('$e');
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Apply filter (VIEW-ONLY)
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    if (filter == 'All') {
      filteredAppointments.value = appointments;
    } else {
      filteredAppointments.value = appointments
          .where((apt) => apt.status.toLowerCase() == filter.toLowerCase())
          .toList();
    }
  }

  // Refresh appointments
  Future<void> refreshAppointments() async {
    await loadAppointments();
  }
}