class DoctorMedicineItem {
  final String name;
  final String dose;
  final String frequency;
  final String duration;

  const DoctorMedicineItem({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dose': dose,
        'frequency': frequency,
        'duration': duration,
      };

  factory DoctorMedicineItem.fromJson(Map<String, dynamic> json) =>
      DoctorMedicineItem(
        name: json['name'] as String? ?? '',
        dose: json['dose'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
      );
}

class DoctorPrescriptionModel {
  final int id;
  final int? appointmentId;
  final int doctorId;
  final int patientId;
  final String? patientAge;
  final String? diagnosis;
  final List<DoctorMedicineItem> medicines;
  final List<String> testsSuggested;
  final String? notes;
  final String? pdfUrl;
  final DateTime? createdAt;

  const DoctorPrescriptionModel({
    required this.id,
    this.appointmentId,
    required this.doctorId,
    required this.patientId,
    this.patientAge,
    this.diagnosis,
    this.medicines = const [],
    this.testsSuggested = const [],
    this.notes,
    this.pdfUrl,
    this.createdAt,
  });

  factory DoctorPrescriptionModel.fromJson(Map<String, dynamic> json) {
    final medsRaw = json['medicines'];
    final meds = medsRaw is List
        ? medsRaw
            .map((e) =>
                DoctorMedicineItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DoctorMedicineItem>[];

    final testsRaw = json['testsSuggested'];
    final tests = testsRaw is List
        ? testsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return DoctorPrescriptionModel(
      id: json['id'] as int,
      appointmentId: json['appointmentId'] as int?,
      doctorId: json['doctorId'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      patientAge: json['patientAge'] as String?,
      diagnosis: json['diagnosis'] as String?,
      medicines: meds,
      testsSuggested: tests,
      notes: json['notes'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
