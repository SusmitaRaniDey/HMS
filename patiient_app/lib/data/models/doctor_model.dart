import '../../config/environment.dart';

class DoctorModel {
  final int id;
  final String name;
  final String degrees;
  final String specialty;
  final int experience;
  final String workingAt;
  final double onlineFee;
  final double offlineFee;
  final String? profilePic;
  final String biography;
  final List<String>? languages;
  final Map<String, dynamic>? slots;
  final List<DoctorConsultationSchedule> workingDays;
  final List<DoctorConsultationSchedule> onlineSchedule;
  final int? consultLimitPerDay;

  DoctorModel({
    required this.id,
    required this.name,
    required this.degrees,
    required this.specialty,
    required this.experience,
    required this.workingAt,
    required this.onlineFee,
    required this.offlineFee,
    this.profilePic,
    required this.biography,
    this.languages,
    this.slots,
    this.workingDays = const [],
    this.onlineSchedule = const [],
    this.consultLimitPerDay,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Doctor',
      degrees: json['degrees'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      experience: json['experience'] as int? ?? 0,
      workingAt: json['working_at'] as String? ?? '',
      onlineFee: _parseFee(json['onlineFee'] ?? json['fee']),
      offlineFee: _parseFee(json['offlineFee'] ?? json['fee']),
      profilePic: Environment.resolveMediaUrl(
        json['profilePic'] ?? json['profile_pic'],
      ),
      biography: json['biography'] as String? ?? '',
      languages: json['languages'] != null
          ? List<String>.from(json['languages'] as List)
          : null,
      slots: json['slots'] as Map<String, dynamic>?,
      workingDays: _parseSchedules(json['workingDays'] ?? json['working_days']),
      onlineSchedule: _parseSchedules(
        json['onlineSchedule'] ?? json['online_schedule'],
      ),
      consultLimitPerDay: json['consultLimitPerDay'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'degrees': degrees,
      'specialty': specialty,
      'experience': experience,
      'working_at': workingAt,
      'fee': offlineFee,
      'onlineFee': onlineFee,
      'offlineFee': offlineFee,
      if (profilePic != null) 'profilePic': profilePic,
      'biography': biography,
      if (languages != null) 'languages': languages,
      if (slots != null) 'slots': slots,
      'workingDays': workingDays.map((item) => item.toJson()).toList(),
      'onlineSchedule': onlineSchedule.map((item) => item.toJson()).toList(),
      if (consultLimitPerDay != null) 'consultLimitPerDay': consultLimitPerDay,
    };
  }

  // Helper getter for display
  String get experienceText => '$experience years';
  double get fee => offlineFee;
  String get feeText => feeTextForType('offline');
  double feeForType(String type) => type == 'online' ? onlineFee : offlineFee;
  String feeTextForType(String type) =>
      '৳${feeForType(type).toStringAsFixed(0)}';
}

class DoctorConsultationSchedule {
  final String day;
  final String startTime;
  final String endTime;

  const DoctorConsultationSchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory DoctorConsultationSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorConsultationSchedule(
      day: json['day']?.toString() ?? '',
      startTime: (json['startTime'] ?? json['start_time'])?.toString() ?? '',
      endTime: (json['endTime'] ?? json['end_time'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
  };
}

double _parseFee(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<DoctorConsultationSchedule> _parseSchedules(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => DoctorConsultationSchedule.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}
