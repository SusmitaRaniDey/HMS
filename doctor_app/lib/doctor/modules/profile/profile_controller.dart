import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/doctor_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';
import '../auth/auth_controller.dart';

class ProfileController extends GetxController {
  final AuthProvider _provider = AuthProvider();
  final StorageService _storage = Get.find<StorageService>(tag: 'doctor');
  final AuthController _authController = Get.find<AuthController>(tag: 'doctor');

  // Observables
  final Rx<DoctorModel?> doctor = Rx<DoctorModel?>(null);
  final isLoading = false.obs;

  // Change Password Form Controllers
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Load profile from storage (VIEW-ONLY)
  void loadProfile() {
    final doctorData = _storage.getDoctor();
    if (doctorData != null) {
      doctor.value = DoctorModel.fromJson(doctorData);
    }
  }

  // Refresh profile from API
  Future<void> refreshProfile() async {
    try {
      isLoading.value = true;
      final updatedDoctor = await _provider.getProfile();
      await _storage.saveDoctor(updatedDoctor.toJson());
      doctor.value = updatedDoctor;
      Helpers.showSuccessSnackbar('Success', 'Profile refreshed');
    } catch (e) {
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Change password
  Future<void> changePassword() async {
    if (!_validatePasswordForm()) return;

    try {
      isLoading.value = true;

      await _provider.changePassword(
        oldPassword: oldPasswordController.text,
        newPassword: newPasswordController.text,
      );

      Helpers.showSuccessSnackbar('Success', 'Password changed successfully!');

      // Clear form
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.back();
    } catch (e) {
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool _validatePasswordForm() {
    final oldPassword = oldPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (oldPassword.isEmpty) {
      Helpers.showErrorSnackbar('Validation Error', 'Please enter your current password');
      return false;
    }

    if (newPassword.isEmpty || newPassword.length < 6) {
      Helpers.showErrorSnackbar('Validation Error', 'New password must be at least 6 characters');
      return false;
    }

    if (newPassword != confirmPassword) {
      Helpers.showErrorSnackbar('Validation Error', 'Passwords do not match');
      return false;
    }

    if (oldPassword == newPassword) {
      Helpers.showErrorSnackbar('Validation Error', 'New password must be different from current password');
      return false;
    }

    return true;
  }

  // Logout
  Future<void> logout() async {
    await _authController.logout();
  }
}