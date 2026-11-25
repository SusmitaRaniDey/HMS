class MedicineDetail {
  final String name;
  final String dose;
  final String frequency;
  final String duration;

  MedicineDetail({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
  });

  factory MedicineDetail.fromJson(Map<String, dynamic> json) {
    return MedicineDetail(
      name: json['name']?.toString() ?? '',
      dose: json['dose']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}

class DoctorSummary {
  final int id;
  final String name;
  final String specialty;
  final String? degrees;
  final String? phone;

  DoctorSummary({
    required this.id,
    required this.name,
    required this.specialty,
    this.degrees,
    this.phone,
  });

  factory DoctorSummary.fromJson(Map<String, dynamic> json) {
    return DoctorSummary(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      degrees: json['degrees']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class PatientSummary {
  final int id;
  final String name;
  final String phone;

  PatientSummary({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    return PatientSummary(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class PrescriptionHistoryModel {
  final int id;
  final int? appointmentId;
  final String? patientAge;
  final String? diagnosis;
  final List<MedicineDetail> medicines;
  final List<String> testsSuggested;
  final String? notes;
  final DateTime createdAt;
  final DoctorSummary? doctor;
  final PatientSummary patient;

  PrescriptionHistoryModel({
    required this.id,
    this.appointmentId,
    this.patientAge,
    this.diagnosis,
    required this.medicines,
    required this.testsSuggested,
    this.notes,
    required this.createdAt,
    this.doctor,
    required this.patient,
  });

  factory PrescriptionHistoryModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionHistoryModel(
      id: json['id'] ?? 0,
      appointmentId: json['appointmentId'],
      patientAge: json['patientAge']?.toString(),
      diagnosis: json['diagnosis']?.toString(),
      medicines: (json['medicines'] as List<dynamic>? ?? [])
          .map((m) => MedicineDetail.fromJson(m as Map<String, dynamic>))
          .toList(),
      testsSuggested: (json['testsSuggested'] as List<dynamic>? ?? [])
          .map((t) => t.toString())
          .toList(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      doctor: json['doctor'] != null
          ? DoctorSummary.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      patient: PatientSummary.fromJson(
          json['patient'] as Map<String, dynamic>? ?? {}),
    );
  }
}
