import 'package:get/get.dart';
import '../services/api_services.dart';
import '../utils/helpers.dart';

class EmergencyController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final isLoading = false.obs;
  final dashboard = <String, dynamic>{}.obs;
  final doctors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.get('/admin-auth/emergency-consultations/dashboard'),
        _api.get('/admin-auth/doctors'),
      ]);
      dashboard.assignAll(Map<String, dynamic>.from(results[0].data));
      final rawDoctors = results[1].data is Map
          ? (results[1].data['data'] ?? results[1].data['doctors'] ?? [])
          : results[1].data;
      doctors.assignAll(
        (rawDoctors as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (e) {
      Get.snackbar('Unable to load emergency dashboard', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createAvailability(
    int doctorId,
    DateTime from,
    DateTime until,
    double? fee,
  ) async {
    isLoading.value = true;
    try {
      await _api.post(
        '/admin-auth/emergency-doctors',
        data: {
          'doctorId': doctorId,
          'availableFrom': from.toUtc().toIso8601String(),
          'availableUntil': until.toUtc().toIso8601String(),
          'isEnabled': true,
          'enabledByAdmin': true,
          if (fee != null) 'emergencyFee': fee,
        },
      );
      Get.back();
      Get.snackbar('Emergency Doctors', 'Availability saved');
      await refreshData();
    } catch (e) {
      Get.snackbar('Save failed', e.toString());
      isLoading.value = false;
    }
  }

  Future<void> disable(int doctorId) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Turn Off Availability',
      message:
          'Are you sure you want to turn off this doctor\'s emergency availability?',
      confirmText: 'Turn Off',
    );
    if (!confirmed) return;

    try {
      await _api.post('/admin-auth/emergency-doctors/$doctorId/off');
      await refreshData();
    } catch (e) {
      Get.snackbar('Update failed', e.toString());
    }
  }
}
