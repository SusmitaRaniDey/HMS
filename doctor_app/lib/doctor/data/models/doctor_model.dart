import '../../config/environment.dart';

class DoctorModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String specialty;
  final String? degrees;
  final int? experience;
  final String? workingAt;
  final double? onlineFee;
  final double? offlineFee;
  final String? profilePic;
  final String? biography;
  final List<String>? languages;
  final List<String>? slots;
  final List<String>? availableSlots;
  final List<DoctorDaySchedule> workingDays;
  final List<DoctorDaySchedule> onlineSchedule;
  final DateTime? createdAt;

  DoctorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.specialty,
    this.degrees,
    this.experience,
    this.workingAt,
    this.onlineFee,
    this.offlineFee,
    this.profilePic,
    this.biography,
    this.languages,
    this.slots,
    this.availableSlots,
    this.workingDays = const [],
    this.onlineSchedule = const [],
    this.createdAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String,
      degrees: json['degrees'] as String?,
      experience: json['experience'] as int?,
      workingAt: json['working_at'] as String?,
      onlineFee: _parseFee(json['onlineFee'] ?? json['fee']),
      offlineFee: _parseFee(json['offlineFee'] ?? json['fee']),
      profilePic: Environment.resolveMediaUrl(
        json['profilePic'] ?? json['profile_pic'],
      ),
      biography: json['biography'] as String?,
      languages: json['languages'] is List
          ? (json['languages'] as List).map((e) => e.toString()).toList()
          : null,
      slots: json['slots'] is List
          ? (json['slots'] as List).map((e) => e.toString()).toList()
          : null,
      availableSlots: json['available_slots'] is List
          ? (json['available_slots'] as List).map((e) => e.toString()).toList()
          : null,
      workingDays: _parseSchedules(json['workingDays'] ?? json['working_days']),
      onlineSchedule: _parseSchedules(
        json['onlineSchedule'] ?? json['online_schedule'],
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'specialty': specialty,
    'degrees': degrees,
    'experience': experience,
    'working_at': workingAt,
    'fee': offlineFee,
    'onlineFee': onlineFee,
    'offlineFee': offlineFee,
    'profilePic': profilePic,
    'biography': biography,
    'languages': languages,
    'slots': slots,
    'available_slots': availableSlots,
    'workingDays': workingDays.map((item) => item.toJson()).toList(),
    'onlineSchedule': onlineSchedule.map((item) => item.toJson()).toList(),
    'createdAt': createdAt?.toIso8601String(),
  };

  String get experienceText => experience != null ? '$experience years' : 'N/A';
  double? get fee => offlineFee;
  String get feeText => offlineFeeText;
  String get onlineFeeText => _formatFee(onlineFee);
  String get offlineFeeText => _formatFee(offlineFee);
}

class DoctorDaySchedule {
  final String day;
  final String startTime;
  final String endTime;

  const DoctorDaySchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory DoctorDaySchedule.fromJson(Map<String, dynamic> json) {
    return DoctorDaySchedule(
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

double? _parseFee(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

List<DoctorDaySchedule> _parseSchedules(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => DoctorDaySchedule.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList();
}

String _formatFee(double? fee) =>
    fee == null ? 'N/A' : '৳${fee.toStringAsFixed(0)}';
