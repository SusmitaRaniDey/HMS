import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class WelcomeController extends GetxController {
  void navigateToLogin() {
    Get.toNamed(AppRoutes.LOGIN);
  }

  void navigateToRegister() {
    Get.toNamed(AppRoutes.REGISTER);
  }
}