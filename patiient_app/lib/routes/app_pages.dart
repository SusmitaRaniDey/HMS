import 'package:get/get.dart';

import '../modules/appointments/appointment_detail_screen.dart';
import '../modules/appointments/appointments_controller.dart';
import '../modules/appointments/appointments_screen.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/bookings/booking_detail_screen.dart';
import '../modules/bookings/bookings_controller.dart';
import '../modules/bookings/bookings_screen.dart';
import '../modules/diagnostics/book_diagnostic_screen.dart';
import '../modules/diagnostics/diagnostic_detail_screen.dart';
import '../modules/diagnostics/diagnostics_controller.dart';
import '../modules/diagnostics/diagnostics_list_screen.dart';
import '../modules/doctors/book_appointment_screen.dart';
import '../modules/doctors/doctor_detail_screen.dart';
import '../modules/doctors/doctors_controller.dart';
import '../modules/doctors/doctors_list_screen.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/home_screen.dart';
import '../modules/prescriptions/prescription_detail_screen.dart';
import '../modules/prescriptions/prescriptions_controller.dart';
import '../modules/prescriptions/prescriptions_screen.dart';
import '../modules/profile/change_password_screen.dart';
import '../modules/profile/edit_profile_screen.dart';
import '../modules/profile/profile_controller.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/refunds/my_refund_requests_screen.dart';
import '../modules/welcome/welcome_controller.dart';
import '../modules/welcome/welcome_screen.dart';
import '../modules/emergency/emergency_doctors_controller.dart';
import '../modules/emergency/emergency_doctors_screen.dart';
import '../modules/emergency/emergency_payment_controller.dart';
import '../modules/emergency/emergency_payment_screen.dart';
import '../modules/emergency/emergency_payment_result_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.WELCOME,
      page: () => const WelcomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WelcomeController>(() => WelcomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.EMERGENCY_DOCTORS,
      page: () => const EmergencyDoctorsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EmergencyDoctorsController());
      }),
    ),
    GetPage(
      name: AppRoutes.EMERGENCY_PAYMENT,
      page: () => const EmergencyPaymentScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EmergencyPaymentController());
      }),
    ),
    GetPage(
      name: AppRoutes.EMERGENCY_PAYMENT_SUCCESS,
      page: () => const EmergencyPaymentSuccessScreen(),
    ),
    GetPage(
      name: AppRoutes.EMERGENCY_PAYMENT_FAILED,
      page: () => const EmergencyPaymentFailedScreen(),
    ),
    GetPage(
      name: AppRoutes.DOCTORS,
      page: () => const DoctorsListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DoctorsController>(() => DoctorsController());
      }),
    ),
    GetPage(
      name: AppRoutes.DOCTOR_DETAIL,
      page: () => const DoctorDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.BOOK_APPOINTMENT,
      page: () => const BookAppointmentScreen(),
    ),
    GetPage(
      name: AppRoutes.DIAGNOSTICS,
      page: () => const DiagnosticsListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DiagnosticsController>(() => DiagnosticsController());
      }),
    ),
    GetPage(
      name: AppRoutes.DIAGNOSTIC_DETAIL,
      page: () => const DiagnosticDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.BOOK_DIAGNOSTIC,
      page: () => const BookDiagnosticScreen(),
    ),
    GetPage(
      name: AppRoutes.APPOINTMENTS,
      page: () => const AppointmentsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AppointmentsController>(() => AppointmentsController());
      }),
    ),
    GetPage(
      name: AppRoutes.APPOINTMENT_DETAIL,
      page: () => const AppointmentDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AppointmentsController>(() => AppointmentsController());
      }),
    ),
    GetPage(
      name: AppRoutes.BOOKINGS,
      page: () => const BookingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BookingsController>(() => BookingsController());
      }),
    ),
    GetPage(
      name: AppRoutes.BOOKING_DETAIL,
      page: () => const BookingDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProfileController>(() => ProfileController());
      }),
    ),
    GetPage(
      name: AppRoutes.EDIT_PROFILE,
      page: () => const EditProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.CHANGE_PASSWORD,
      page: () => const ChangePasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.PRESCRIPTIONS,
      page: () => const PrescriptionsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PrescriptionsController>(() => PrescriptionsController());
      }),
    ),
    GetPage(
      name: AppRoutes.PRESCRIPTION_DETAIL,
      page: () => const PrescriptionDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.REFUNDS,
      page: () => const MyRefundRequestsScreen(),
    ),
  ];
}
