import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../models/refund_request_model.dart';

class RefundProvider {
  final ApiService _apiService = Get.find<ApiService>();

  Future<RefundRequestModel?> getByAppointment(int appointmentId) async {
    final response = await _apiService.get('/refunds/appointment/$appointmentId');
    final data = response.data;
    if (data is Map<String, dynamic> && data['exists'] == false) return null;
    return RefundRequestModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<RefundRequestModel>> getMine() async {
    final response = await _apiService.get('/refunds/my');
    return (response.data as List)
        .map((json) => RefundRequestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<RefundRequestModel> create({
    required int appointmentId,
    required String reason,
    String? patientNote,
    required String refundToAccount,
  }) async {
    final response = await _apiService.post(
      '/refunds',
      data: {
        'appointmentId': appointmentId,
        'reason': reason,
        if (patientNote != null && patientNote.isNotEmpty)
          'patientNote': patientNote,
        'refundToAccount': refundToAccount,
      },
    );
    return RefundRequestModel.fromJson(response.data as Map<String, dynamic>);
  }
}
