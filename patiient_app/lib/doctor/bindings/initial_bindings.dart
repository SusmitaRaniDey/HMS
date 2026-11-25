import 'package:get/get.dart';

import '../modules/auth/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize AuthController as permanent
    Get.put(AuthController(), permanent: true);
  }
}