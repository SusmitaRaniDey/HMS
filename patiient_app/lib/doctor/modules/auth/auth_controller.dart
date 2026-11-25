import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/doctor_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';

class AuthController extends GetxController {
  final AuthProvider _authProvider = AuthProvider();
  final StorageService _storageService = Get.find<StorageService>(tag: 'doctor');

  // Observables
  final isLoading = false.obs;
  final Rx<DoctorModel?> currentDoctor = Rx<DoctorModel?>(null);

  // Login Form Controllers
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDoctorData();
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.onClose();
  }

  // Load doctor data from storage
  void loadDoctorData() {
    final doctorData = _storageService.getDoctor();
    if (doctorData != null) {
      currentDoctor.value = DoctorModel.fromJson(doctorData);
    }
  }

  // ========== LOGIN ==========
  Future<void> login() async {
    if (!_validateLoginForm()) return;

    try {
      isLoading.value = true;

      final result = await _authProvider.login(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text,
      );

      // Save token first so subsequent API calls are authenticated
      final token = result['accessToken'] as String? ??
          (result['data'] is Map
              ? (result['data'] as Map)['accessToken'] as String?
              : null);
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not received from server');
      }
      await _storageService.saveToken(token);

      // Fetch full profile (login response only returns partial data)
      final fullProfile = await _authProvider.getProfile();
      await _storageService.saveDoctor(fullProfile.toJson());
      currentDoctor.value = fullProfile;

      Helpers.showSuccessSnackbar('Success', 'Login successful!');

      // Clear controllers
      loginEmailController.clear();
      loginPasswordController.clear();

      // Navigate to dashboard
      Get.offAllNamed(AppRoutes.DASHBOARD);
    } catch (e) {
      Helpers.showErrorSnackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateLoginForm() {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text;

    if (email.isEmpty) {
      Helpers.showErrorSnackbar('Validation Error', 'Please enter your email');
      return false;
    }

    if (!Helpers.isValidEmail(email)) {
      Helpers.showErrorSnackbar('Validation Error', 'Please enter a valid email');
      return false;
    }

    if (password.isEmpty) {
      Helpers.showErrorSnackbar('Validation Error', 'Please enter your password');
      return false;
    }

    return true;
  }

  // ========== LOGOUT ==========
  Future<void> logout() async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
    );

    if (!confirmed) return;

    try {
      await _storageService.clearAll();
      currentDoctor.value = null;

      Helpers.showSuccessSnackbar('Success', 'Logged out successfully');

      Get.offAllNamed(AppRoutes.ROOT_WELCOME);
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to logout');
    }
  }
}