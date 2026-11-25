import 'package:get/get.dart';
import '../controller/patient_history_controller.dart';

class PatientHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PatientHistoryController>(() => PatientHistoryController());
  }
}
