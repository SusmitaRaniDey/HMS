import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:patient_app/doctor/bindings/initial_bindings.dart';
import 'package:patient_app/doctor/routes/app_pages.dart';
import 'package:patient_app/doctor/routes/app_routes.dart';
import 'package:patient_app/doctor/services/api_service.dart';
import 'package:patient_app/doctor/services/storage_service.dart';
import 'package:patient_app/doctor/theme/app_theme.dart';

var logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  logger.i('Initializing Doctor Storage Service...');
  Get.put(StorageService(), tag: 'doctor');
  logger.i('Doctor Storage Service Initialized');

  logger.i('Initializing Doctor API Service...');
  Get.put(ApiService(), tag: 'doctor');
  logger.i('Doctor API Service Initialized');

  logger.i('Doctor services initialized successfully.');
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
          title: 'Doctor App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialBinding: InitialBinding(),
          initialRoute: AppRoutes.WELCOME,
          getPages: AppPages.pages,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
