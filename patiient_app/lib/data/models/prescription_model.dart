class MedicineItem {
  final String name;
  final String dose;
  final String frequency;
  final String duration;

  const MedicineItem({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
  });

  factory MedicineItem.fromJson(Map<String, dynamic> json) => MedicineItem(
        name: json['name'] as String? ?? '',
        dose: json['dose'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dose': dose,
        'frequency': frequency,
        'duration': duration,
      };
}

class PrescriptionModel {
  final int id;
  final int? appointmentId;
  final int doctorId;
  final int patientId;
  final String? patientAge;
  final String? diagnosis;
  final List<MedicineItem> medicines;
  final List<String> testsSuggested;
  final String? notes;
  final String? pdfUrl;
  final DateTime? createdAt;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? patient;

  const PrescriptionModel({
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
    this.doctor,
    this.patient,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final medicinesRaw = json['medicines'];
    final medicines = medicinesRaw is List
        ? medicinesRaw
            .map((e) => MedicineItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MedicineItem>[];

    final testsRaw = json['testsSuggested'];
    final tests = testsRaw is List
        ? testsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return PrescriptionModel(
      id: json['id'] as int,
      appointmentId: json['appointmentId'] as int?,
      doctorId: json['doctorId'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      patientAge: json['patientAge'] as String?,
      diagnosis: json['diagnosis'] as String?,
      medicines: medicines,
      testsSuggested: tests,
      notes: json['notes'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      doctor: json['doctor'] as Map<String, dynamic>?,
      patient: json['patient'] as Map<String, dynamic>?,
    );
  }

  String get doctorName =>
      doctor?['name'] as String? ?? 'Dr. Unknown';

  String get patientName =>
      patient?['name'] as String? ?? 'Patient';

  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
}
