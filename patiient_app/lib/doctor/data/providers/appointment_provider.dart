import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../../config/environment.dart';
import '../models/appointment_model.dart';

class AppointmentProvider {
  final ApiService _apiService = Get.find<ApiService>(tag: 'doctor');

  // Get All Appointments (with pagination and filters)
  Future<Map<String, dynamic>> getAppointments({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await _apiService.get(
      Environment.APPOINTMENTS,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'data': data is List ? data : []};
  }

  // Get Pending Appointments
  Future<List<AppointmentModel>> getPendingAppointments() async {
    final response = await _apiService.get(Environment.APPOINTMENTS_PENDING);
    return _parseList(response.data);
  }

  // Get Confirmed Appointments
  Future<List<AppointmentModel>> getConfirmedAppointments() async {
    final response = await _apiService.get(Environment.APPOINTMENTS_CONFIRMED);
    return _parseList(response.data);
  }

  // Get Today's Appointments
  Future<List<AppointmentModel>> getTodayAppointments() async {
    final response = await _apiService.get(Environment.APPOINTMENTS_TODAY);
    return _parseList(response.data);
  }

  // Get Upcoming Appointments
  Future<List<AppointmentModel>> getUpcomingAppointments() async {
    final response = await _apiService.get(Environment.APPOINTMENTS_UPCOMING);
    return _parseList(response.data);
  }

  // Get Appointment History (with pagination)
  Future<Map<String, dynamic>> getAppointmentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get(
      Environment.APPOINTMENTS_HISTORY,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'data': data is List ? data : []};
  }

  // Get Appointment Details
  Future<AppointmentModel> getAppointmentDetail(int appointmentId) async {
    final response = await _apiService.get(
      Environment.appointmentDetail(appointmentId),
    );
    final data = response.data;
    final json = data is Map<String, dynamic> ? data : (data as Map).cast<String, dynamic>();
    return AppointmentModel.fromJson(json);
  }

  // Safely extract a list from any response shape
  List<AppointmentModel> _parseList(dynamic data) {
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List<dynamic>;
    } else {
      return [];
    }
    return list
        .whereType<Map>()
        .map((json) => AppointmentModel.fromJson(json.cast<String, dynamic>()))
        .toList();
  }
}
