import 'dart:async';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class EmergencyDoctorsController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final doctors = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    refreshDoctors();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refreshDoctors(silent: true),
    );
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshDoctors({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final response = await _api.get('/patient/emergency-doctors');
      doctors.assignAll(
        (response.data as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (e) {
      if (!silent) Get.snackbar('Unable to refresh', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> consultNow(Map<String, dynamic> doctor) async {
    await Get.toNamed(AppRoutes.EMERGENCY_PAYMENT, arguments: doctor);
    refreshDoctors(silent: true);
  }
}
