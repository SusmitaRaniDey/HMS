import 'package:get/get.dart';
import '../../data/models/prescription_model.dart';
import '../../data/providers/prescription_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';

class PrescriptionsController extends GetxController {
  final PrescriptionProvider _provider = PrescriptionProvider();
  final StorageService _storage = Get.find<StorageService>();

  final isLoading = false.obs;
  final prescriptions = <PrescriptionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    try {
      isLoading.value = true;
      final patient = _storage.getPatient();
      if (patient == null) return;
      final patientId = patient['id'] as int;
      final list = await _provider.getMyPrescriptions(patientId);
      prescriptions.value = list;
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to load prescriptions');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() => loadPrescriptions();
}
