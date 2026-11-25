import 'package:get/get.dart';
import '../models/prescription_history_model.dart';
import '../services/api_services.dart';
import '../utils/helpers.dart';

class PatientHistoryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final prescriptions = <PrescriptionHistoryModel>[].obs;
  final patientName = ''.obs;
  final patientPhone = ''.obs;
  int patientId = 0;

  @override
  void onInit() {
    super.onInit();
    // Route-based usage: read args and auto-load
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      patientId = args['patientId'] as int? ?? 0;
      patientName.value = args['patientName'] as String? ?? '';
      patientPhone.value = args['patientPhone'] as String? ?? '';
      loadHistory();
    }
    // Dialog usage: caller invokes setPatient() after Get.put()
  }

  /// Called by the dialog path — sets patient info and fetches history.
  void setPatient(int id, String name, String phone) {
    patientId = id;
    patientName.value = name;
    patientPhone.value = phone;
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      prescriptions.clear();
      final response = await _apiService.get(
        '/admin-auth/users/$patientId/prescriptions',
      );

      if (response.data != null) {
        prescriptions.value = (response.data as List)
            .map((json) =>
                PrescriptionHistoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to load patient history');
    } finally {
      isLoading.value = false;
    }
  }
}
