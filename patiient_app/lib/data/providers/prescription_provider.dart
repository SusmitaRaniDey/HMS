import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../models/prescription_model.dart';

class PrescriptionProvider {
  final ApiService _api = Get.find<ApiService>();

  Future<List<PrescriptionModel>> getMyPrescriptions(int patientId) async {
    final response = await _api.get('/prescriptions/patient/$patientId');
    final data = response.data as List;
    return data
        .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrescriptionModel> getPrescriptionById(int id) async {
    final response = await _api.get('/prescriptions/$id');
    return PrescriptionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PrescriptionModel> getPrescriptionByAppointment(
      int appointmentId) async {
    final response =
        await _api.get('/prescriptions/appointment/$appointmentId');
    return PrescriptionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Returns the full URL to stream/download the PDF
  String getPdfDownloadUrl(int prescriptionId) {
    // Handled by the /prescriptions/:id/download endpoint
    // The ApiService base URL is used
    return '/prescriptions/$prescriptionId/download';
  }
}
