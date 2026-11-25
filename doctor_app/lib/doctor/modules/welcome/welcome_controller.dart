import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class DoctorWelcomeController extends GetxController {
  void navigateToLogin() {
    Get.toNamed(AppRoutes.LOGIN);
  }
}