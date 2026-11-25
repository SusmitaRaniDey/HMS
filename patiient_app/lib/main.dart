import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:patient_app/routes/app_pages.dart';
import 'package:patient_app/routes/app_routes.dart';
import 'package:patient_app/services/api_service.dart';
import 'package:patient_app/services/payment_service.dart';
import 'package:patient_app/services/storage_service.dart';
import 'package:patient_app/theme/app_theme.dart';

import 'bindings/initial_binding.dart';

var logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  logger.i('Initializing Patient Storage Service...');
  await Get.putAsync(() => StorageService().init());
  logger.i('Patient Storage Service Initialized');

  logger.i('Initializing Patient API Service...');
  await Get.putAsync(() => ApiService().init());
  logger.i('Patient API Service Initialized');

  logger.i('Registering Payment Service...');
  Get.put(PaymentService());
  logger.i('Payment Service Registered');

  logger.i('Patient services initialized successfully.');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Patient App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialBinding: InitialBinding(),
          // If a token is already stored locally, skip straight to Home
          // instead of forcing the user through Welcome/Login again.
          // This is a local presence check only (no network round-trip) —
          // an actually-expired token is still caught by the 401
          // interceptor in ApiService on the first real API call.
          initialRoute: Get.find<StorageService>().hasToken()
              ? AppRoutes.HOME
              : AppRoutes.WELCOME,
          getPages: AppPages.routes,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
