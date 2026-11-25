import 'package:get/get.dart';

import '../modules/auth/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Keep the tagged auth controller alive for screens that access it by tag.
    Get.put(AuthController(), tag: 'doctor', permanent: true);
  }
}
