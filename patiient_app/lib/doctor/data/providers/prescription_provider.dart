import 'package:get/get.dart';
import '../models/prescription_model.dart';
import '../../services/api_service.dart';

class DoctorPrescriptionProvider {
  final ApiService _api = Get.find<ApiService>(tag: 'doctor');

  Future<DoctorPrescriptionModel> createPrescription({
    required int appointmentId,
    required int doctorId,
    required int patientId,
    String? patientAge,
    String? diagnosis,
    required List<Map<String, String>> medicines,
    required List<String> testsSuggested,
    String? notes,
    String? patientFcmToken,
  }) async {
    final response = await _api.post(
      '/prescriptions',
      data: {
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'patientId': patientId,
        if (patientAge != null) 'patientAge': patientAge,
        if (diagnosis != null) 'diagnosis': diagnosis,
        'medicines': medicines,
        'testsSuggested': testsSuggested,
        if (notes != null) 'notes': notes,
        if (patientFcmToken != null) 'patientFcmToken': patientFcmToken,
      },
    );
    return DoctorPrescriptionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<DoctorPrescriptionModel?> getPrescriptionByAppointment(
    int appointmentId,
  ) async {
    try {
      final response = await _api.get(
        '/prescriptions/appointment/$appointmentId',
      );
      return DoctorPrescriptionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> fetchDiagnosticNames() async {
    try {
      final response = await _api.get(
        '/diagnostics',
        queryParameters: {'limit': 500, 'includeInactive': false},
      );
      final data = response.data;
      final List<dynamic> items =
          data is Map ? (data['data'] ?? data['items'] ?? []) : (data as List);
      return items
          .map((e) => (e['test_name'] ?? e['testName'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
