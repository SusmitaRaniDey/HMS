import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/diagnostic_model.dart';
import '../../data/providers/booking_provider.dart';
import '../../utils/helpers.dart';

class DiagnosticsController extends GetxController {
  final BookingProvider _provider = BookingProvider();

  // One card per unique item_code — synced live from the Admin Panel's
  // Diagnostics Management module.
  final isLoading = false.obs;
  final groups = <DiagnosticGroupModel>[].obs;
  final searchQuery = ''.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadDiagnostics();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // Loads the grouped diagnostic list from the backend, applying whatever
  // search text is currently set (server-side, across test name / category /
  // item code) so results aren't limited to a single fetched page.
  Future<void> loadDiagnostics() async {
    try {
      isLoading.value = true;
      final result = await _provider.getAllDiagnostics(
        limit: 200,
        search: searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
      );
      final List<dynamic> data = result['data'] as List;
      groups.value = data
          .map((json) => DiagnosticGroupModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Search by test name, category, or item code (debounced, server-side).
  void searchDiagnostics(String query) {
    searchQuery.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadDiagnostics);
  }

  Future<void> refreshDiagnostics() async {
    await loadDiagnostics();
  }
}
