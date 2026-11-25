import 'package:get/get.dart';

import '../modules/appointments/appointment_controller.dart'
    show DoctorAppointmentsController;
import '../modules/appointments/appointment_details_screen.dart';
import '../modules/appointments/appointment_screen.dart';
import '../modules/appointments/appointments_history_screen.dart';
import '../modules/appointments/confirmed_appointment_screen.dart';
import '../modules/appointments/pending_request_screen.dart';
import '../modules/appointments/today_appointments_screen.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/login_screen.dart';
import '../modules/dashboard/dashboard_controller.dart';
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/prescriptions/prescription_form_controller.dart';
import '../modules/prescriptions/prescription_form_screen.dart';
import '../modules/profile/change_password_screen.dart';

import '../modules/profile/profile_controller.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/settings/setting_screen.dart';
import '../modules/welcome/welcome_controller.dart';
import '../modules/welcome/welcome_screen.dart';
import '../modules/emergency/emergency_consultation_controller.dart';
import '../modules/emergency/emergency_consultation_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    // ========== WELCOME & AUTH ==========
    GetPage(
      name: AppRoutes.WELCOME,
      page: () => const WelcomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorWelcomeController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>(tag: 'doctor')) {
          Get.put(AuthController(), tag: 'doctor', permanent: true);
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ========== DASHBOARD ==========
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => const DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.EMERGENCY_CONSULTATION,
      page: () => const EmergencyConsultationScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EmergencyConsultationController());
      }),
    ),

    // ========== APPOINTMENTS ==========
    GetPage(
      name: AppRoutes.APPOINTMENTS,
      page: () => const AppointmentsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorAppointmentsController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.APPOINTMENT_DETAIL,
      page: () => const AppointmentDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorAppointmentsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.PENDING_REQUESTS,
      page: () => const PendingRequestsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorAppointmentsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.CONFIRMED_APPOINTMENTS,
      page: () => const ConfirmedAppointmentsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorAppointmentsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.TODAY_APPOINTMENTS,
      page: () => const TodayAppointmentsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorAppointmentsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.UPCOMING_APPOINTMENTS,
      page: () => const TodayAppointmentsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorAppointmentsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.APPOINTMENT_HISTORY,
      page: () => const AppointmentHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DoctorAppointmentsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ========== PRESCRIPTIONS ==========
    GetPage(
      name: AppRoutes.PRESCRIPTION_FORM,
      page: () => const PrescriptionFormScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PrescriptionFormController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ========== PROFILE ==========
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.CHANGE_PASSWORD,
      page: () => const ChangePasswordScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
