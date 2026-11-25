import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/patient_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';

class AuthController extends GetxController {
  final AuthProvider _authProvider = AuthProvider();
  final StorageService _storageService = Get.find<StorageService>();

  // Observables
  final isLoading = false.obs;
  final Rx<PatientModel?> currentPatient = Rx<PatientModel?>(null);

  // Form Controllers - Login
  final loginEmailPhoneController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final isLoginWithEmail = true.obs;

  // Form Controllers - Register
  final registerNameController = TextEditingController();
  final registerEmailPhoneController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();
  final isRegisterWithEmail = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadPatientData();
  }

  @override
  void onClose() {
    // Dispose controllers
    loginEmailPhoneController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailPhoneController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    super.onClose();
  }

  // ========== LOAD PATIENT DATA ==========
  void loadPatientData() {
    final patientData = _storageService.getPatient();
    if (patientData != null) {
      currentPatient.value = PatientModel.fromJson(patientData);
    }
  }

  // ========== LOGIN ==========
  Future<void> login() async {
    if (!_validateLoginForm()) return;

    try {
      isLoading.value = true;

      final result = await _authProvider.login(
        email: isLoginWithEmail.value
            ? loginEmailPhoneController.text.trim()
            : null,
        phone: !isLoginWithEmail.value
            ? loginEmailPhoneController.text.trim()
            : null,
        password: loginPasswordController.text,
      );

      // Save token and patient data
      await _storageService.saveToken(result['accessToken'] as String);
      await _storageService.savePatient(
        result['patient'] as Map<String, dynamic>,
      );

      currentPatient.value = PatientModel.fromJson(
        result['patient'] as Map<String, dynamic>,
      );

      Helpers.showSuccessSnackbar('Success', 'Login successful!');

      // Navigate to home
      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      Helpers.showErrorSnackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateLoginForm() {
    final emailPhone = loginEmailPhoneController.text.trim();
    final password = loginPasswordController.text;

    if (emailPhone.isEmpty) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter your ${isLoginWithEmail.value ? 'email' : 'phone number'}',
      );
      return false;
    }

    if (isLoginWithEmail.value && !Helpers.isValidEmail(emailPhone)) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter a valid email',
      );
      return false;
    }

    if (!isLoginWithEmail.value && !Helpers.isValidPhone(emailPhone)) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter a valid phone number',
      );
      return false;
    }

    if (password.isEmpty) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter your password',
      );
      return false;
    }

    if (password.length < 6) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Password must be at least 6 characters',
      );
      return false;
    }

    return true;
  }

  // ========== REGISTER ==========
  Future<void> register() async {
    if (!_validateRegisterForm()) return;

    try {
      isLoading.value = true;

      if (isRegisterWithEmail.value) {
        await _authProvider.registerWithEmail(
          name: registerNameController.text.trim(),
          email: registerEmailPhoneController.text.trim(),
          password: registerPasswordController.text,
        );
      } else {
        await _authProvider.registerWithPhone(
          name: registerNameController.text.trim(),
          phone: registerEmailPhoneController.text.trim(),
          password: registerPasswordController.text,
        );
      }

      Helpers.showSuccessSnackbar(
        'Success',
        'Account created successfully! Please login.',
      );

      // Clear form
      _clearRegisterForm();

      // Navigate to login
      Get.offNamed(AppRoutes.LOGIN);
    } catch (e) {
      Helpers.showErrorSnackbar('Registration Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateRegisterForm() {
    final name = registerNameController.text.trim();
    final emailPhone = registerEmailPhoneController.text.trim();
    final password = registerPasswordController.text;
    final confirmPassword = registerConfirmPasswordController.text;

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

    if (emailPhone.isEmpty) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter your ${isRegisterWithEmail.value ? 'email' : 'phone number'}',
      );
      return false;
    }

    if (isRegisterWithEmail.value && !Helpers.isValidEmail(emailPhone)) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter a valid email',
      );
      return false;
    }

    if (!isRegisterWithEmail.value && !Helpers.isValidPhone(emailPhone)) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please enter a valid phone number',
      );
      return false;
    }

    if (password.isEmpty) {
      Helpers.showErrorSnackbar('Validation Error', 'Please enter a password');
      return false;
    }

    if (password.length < 6) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Password must be at least 6 characters',
      );
      return false;
    }

    if (confirmPassword.isEmpty) {
      Helpers.showErrorSnackbar(
        'Validation Error',
        'Please confirm your password',
      );
      return false;
    }

    if (password != confirmPassword) {
      Helpers.showErrorSnackbar('Validation Error', 'Passwords do not match');
      return false;
    }

    return true;
  }

  void _clearRegisterForm() {
    registerNameController.clear();
    registerEmailPhoneController.clear();
    registerPasswordController.clear();
    registerConfirmPasswordController.clear();
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
      currentPatient.value = null;

      Helpers.showSuccessSnackbar('Success', 'Logged out successfully');

      Get.offAllNamed(AppRoutes.WELCOME);
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to logout');
    }
  }

  // ========== TOGGLE LOGIN/REGISTER TYPE ==========
  void toggleLoginType() {
    isLoginWithEmail.value = !isLoginWithEmail.value;
    loginEmailPhoneController.clear();
  }

  void toggleRegisterType() {
    isRegisterWithEmail.value = !isRegisterWithEmail.value;
    registerEmailPhoneController.clear();
  }
}
