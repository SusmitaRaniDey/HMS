import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/patient_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';
import '../auth/auth_controller.dart';

class ProfileController extends GetxController {
  final AuthProvider _provider = AuthProvider();
  final StorageService _storage = Get.find<StorageService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  final Rx<PatientModel?> patient = Rx<PatientModel?>(null);
  final isLoading = false.obs;

  // Edit Profile Form Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Load profile from storage
  void loadProfile() {
    final patientData = _storage.getPatient();
    if (patientData != null) {
      patient.value = PatientModel.fromJson(patientData);
      _populateEditForm();
    }
  }

  // Populate edit form with current data
  void _populateEditForm() {
    if (patient.value != null) {
      nameController.text = patient.value!.name;
      emailController.text = patient.value!.email ?? '';
      phoneController.text = patient.value!.phone ?? '';
    }
  }

  // Update profile
  Future<void> updateProfile() async {
    if (!_validateUpdateForm()) return;

    try {
      isLoading.value = true;

      final updatedPatient = await _provider.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim().isNotEmpty
            ? emailController.text.trim()
            : null,
        phone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
      );

      // Update storage
      await _storage.savePatient(updatedPatient.toJson());
      patient.value = updatedPatient;

      Helpers.showSuccessSnackbar('Success', 'Profile updated successfully!');
      Get.back();
    } catch (e) {
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateUpdateForm() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      Helpers.showErrorSnackbar('Validation Error', 'Please enter your name');
      return false;
    }

    if (name.length < 2) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Name must be at least 2 characters',
      );
      return false;
    }

    return true;
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
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter your current password',
      );
      return false;
    }

    if (newPassword.isEmpty) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter a new password',
      );
      return false;
    }

    if (newPassword.length < 6) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'New password must be at least 6 characters',
      );
      return false;
    }

    if (confirmPassword.isEmpty) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please confirm your new password',
      );
      return false;
    }

    if (newPassword != confirmPassword) {
      Helpers.showErrorSnackbar('Validation Error', 'Passwords do not match');
      return false;
    }

    if (oldPassword == newPassword) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'New password must be different from current password',
      );
      return false;
    }

    return true;
  }

  // Logout
  Future<void> logout() async {
    await _authController.logout();
  }
}