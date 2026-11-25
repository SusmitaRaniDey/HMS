import 'package:get/get.dart';
import '../models/prescription_model.dart';
import '../../services/api_service.dart';

class MedicineSuggestion {
  final int sl;
  final String tradeName;
  final String genericName;
  final String company;
  final String dosageForm;

  const MedicineSuggestion({
    required this.sl,
    required this.tradeName,
    required this.genericName,
    required this.company,
    required this.dosageForm,
  });

  factory MedicineSuggestion.fromJson(Map<String, dynamic> json) =>
      MedicineSuggestion(
        sl: (json['sl'] as num).toInt(),
        tradeName: json['trade_name']?.toString() ?? '',
        genericName: json['generic_name_with_strength']?.toString() ?? '',
        company: json['company']?.toString() ?? '',
        dosageForm: json['dosage_form']?.toString() ?? '',
      );
}

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

  // Distinct diagnostic test names from the Admin Panel's Diagnostics
  // Management catalogue, for autocomplete when a doctor suggests a test.
  // The doctor can still type a name that isn't in this list.
  Future<List<String>> fetchDiagnosticNames() async {
    try {
      final response = await _api.get('/diagnostics/names');
      final data = response.data;
      final List<dynamic> items = data is List
          ? data
          : (data is Map ? (data['data'] ?? const []) : const []);
      return items.map((e) => e.toString()).where((name) => name.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MedicineSuggestion>> searchMedicines(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];
    final response = await _api.get(
      '/medicine-data/suggestions',
      queryParameters: {'q': term, 'limit': 12},
    );
    final data = response.data as List? ?? const [];
    return data
        .map(
          (item) => MedicineSuggestion.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((item) => item.tradeName.isNotEmpty)
        .toList();
  }
}
