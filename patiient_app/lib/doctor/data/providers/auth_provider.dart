import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../../config/environment.dart';
import '../models/doctor_model.dart';

class AuthProvider {
  final ApiService _apiService = Get.find<ApiService>(tag: 'doctor');

  // Login - Only authentication method for doctors
  // Doctors are created by admin, they can only login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      Environment.AUTH_LOGIN,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {};
  }

  // Get Profile (Read-only)
  Future<DoctorModel> getProfile() async {
    final response = await _apiService.get(Environment.PROFILE);
    final data = response.data;
    Map<String, dynamic> json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is Map) {
      json = data.cast<String, dynamic>();
    } else {
      throw Exception('Unexpected profile response format');
    }
    if (json['data'] is Map) {
      json = (json['data'] as Map).cast<String, dynamic>();
    }
    return DoctorModel.fromJson(json);
  }

  // Change Password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiService.post(
      Environment.PROFILE_CHANGE_PASSWORD,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }
}