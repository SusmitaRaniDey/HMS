import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/environment.dart';
import '../models/patient_model.dart';

class AuthProvider {
  final ApiService _apiService = Get.find<ApiService>();

  // Register with Email
  Future<Map<String, dynamic>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      Environment.AUTH_REGISTER_EMAIL,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Register with Phone
  Future<Map<String, dynamic>> registerWithPhone({
    required String name,
    required String phone,
    required String password,
  }) async {
    final response = await _apiService.post(
      Environment.AUTH_REGISTER_PHONE,
      data: {
        'name': name,
        'phone': phone,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Login
  Future<Map<String, dynamic>> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    final response = await _apiService.post(
      Environment.AUTH_LOGIN,
      data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Get Profile
  Future<PatientModel> getProfile() async {
    final response = await _apiService.get(Environment.PROFILE);
    return PatientModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Update Profile
  Future<PatientModel> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    final response = await _apiService.patch(
      Environment.PROFILE,
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      },
    );
    return PatientModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _apiService.post(
      Environment.PROFILE_CHANGE_PASSWORD,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}