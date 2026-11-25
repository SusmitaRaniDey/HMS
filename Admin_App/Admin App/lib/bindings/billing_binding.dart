import 'package:get/get.dart';
import '../controller/billing_controller.dart';

class BillingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillingController>(() => BillingController());
  }
}
