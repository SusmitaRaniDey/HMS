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
    await _fetchAppointments(selectedFilter.value);
  }

  // Apply filter (VIEW-ONLY). Re-fetches from the server scoped to the
  // selected status so appointments beyond page 1 aren't silently dropped
  // (previously this filtered client-side over only the first page).
  Future<void> applyFilter(String filter) async {
    selectedFilter.value = filter;
    await _fetchAppointments(filter);
  }

  // Fetches every page for the given status filter from the server and
  // stores the aggregated result. Uses the backend's `status` query param
  // when a specific filter is selected, and pages through results (rather
  // than trusting a single page) since the backend does not return
  // pagination metadata (total pages/count) to know when to stop otherwise.
  Future<void> _fetchAppointments(String filter) async {
    try {
      isLoading.value = true;
      final String? status = filter == 'All' ? null : filter.toLowerCase();
      final results = <AppointmentModel>[];
      const limit = 50;
      const maxPages = 20; // safety cap (~1000 records) against a runaway loop
      var page = 1;
      while (page <= maxPages) {
        final result = await _provider.getAppointments(
          page: page,
          limit: limit,
          status: status,
        );
        final rawData = result['data'];
        final List<dynamic> data = rawData is List ? rawData : [];
        final pageItems = <AppointmentModel>[];
        for (final item in data.whereType<Map>()) {
          // Parse each record individually so one malformed record doesn't
          // throw and blank the rest of the (otherwise valid) page.
          try {
            pageItems.add(AppointmentModel.fromJson(item.cast<String, dynamic>()));
          } catch (e) {
            debugPrint('Skipping malformed appointment record: $e');
          }
        }
        results.addAll(pageItems);
        // Base the "more pages?" check on the raw page size, not the
        // parsed count, so a malformed record on an otherwise-full page
        // doesn't cause pagination to stop early.
        if (data.length < limit) break;
        page++;
      }

      appointments.value = results;
      filteredAppointments.value = results;
    } catch (e) {
      debugPrint('$e');
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh appointments
  Future<void> refreshAppointments() async {
    await loadAppointments();
  }
}