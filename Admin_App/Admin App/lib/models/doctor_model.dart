import '../config/environment.dart';

// Interface for day schedule configuration
class DaySchedule {
  final String day;
  final String startTime;
  final String endTime;

  DaySchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'],
      startTime: json['start_time'] ?? json['startTime'] ?? '',
      endTime: json['end_time'] ?? json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'startTime': startTime, 'endTime': endTime};
  }
}

class OnlineSchedule {
  final String day;
  final String startTime;
  final String endTime;

  OnlineSchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory OnlineSchedule.fromJson(Map<String, dynamic> json) {
    return OnlineSchedule(
      day: json['day'] ?? json['date'] ?? '',
      startTime: json['start_time'] ?? json['startTime'] ?? '',
      endTime: json['end_time'] ?? json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'startTime': startTime, 'endTime': endTime};
  }
}

class DoctorModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String degrees;
  final String specialty;
  final int experience;
  final String workingAt;
  final double onlineFee;
  final double offlineFee;
  final String? profilePic;
  final String biography;
  final List<String>? languages;
  final Map<String, String>? slots;
  final int? availableSlots;
  final List<DaySchedule>? workingDays;
  final List<OnlineSchedule>? onlineSchedule;
  final int? consultLimitPerDay;
  final String status; // 'active', 'inactive', 'suspended'
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final int? appointmentsCount;

  DoctorModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
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
    this.availableSlots,
    this.workingDays,
    this.onlineSchedule,
    this.consultLimitPerDay,
    this.status = 'active',
    this.suspensionReason,
    this.suspendedAt,
    this.appointmentsCount,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'] ?? '',
      phone: json['phone'],
      degrees: json['degrees'] is List
          ? (json['degrees'] as List).join(', ')
          : json['degrees']?.toString() ?? '',
      specialty: json['specialty'],
      experience: json['experience'],
      workingAt: json['working_at'],
      onlineFee: ((json['onlineFee'] ?? json['fee'] ?? 0) as num).toDouble(),
      offlineFee: ((json['offlineFee'] ?? json['fee'] ?? 0) as num).toDouble(),
      profilePic: Environment.resolveMediaUrl(
        json['profilePic'] ?? json['profile_pic'],
      ),
      biography: json['biography'],
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      slots: json['slots'] != null
          ? Map<String, String>.from(json['slots'])
          : null,
      availableSlots: json['available_slots'],
      workingDays: json['working_days'] != null || json['workingDays'] != null
          ? ((json['working_days'] ?? json['workingDays']) as List)
                .map((item) => DaySchedule.fromJson(item))
                .toList()
          : null,
      onlineSchedule:
          json['online_schedule'] != null || json['onlineSchedule'] != null
          ? ((json['online_schedule'] ?? json['onlineSchedule']) as List)
                .map((item) => OnlineSchedule.fromJson(item))
                .toList()
          : null,
      consultLimitPerDay:
          json['consult_limit_per_day'] ?? json['consultLimitPerDay'] ?? 30,
      status: json['status'] ?? 'active',
      suspensionReason: json['suspensionReason'],
      suspendedAt: json['suspendedAt'] != null
          ? DateTime.parse(json['suspendedAt'])
          : null,
      appointmentsCount: json['appointmentsCount'],
    );
  }

  Map<String, dynamic> toJson({bool includeStatus = false}) {
    final Map<String, dynamic> json = {
      'name': name,
      'email': email,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone,
      'degrees': degrees,
      'specialty': specialty,
      'experience': experience,
      'working_at': workingAt,
      'fee': offlineFee,
      'onlineFee': onlineFee,
      'offlineFee': offlineFee,
      'biography': biography,
      'consultLimitPerDay': consultLimitPerDay ?? 30,
    };

    if (includeStatus) {
      json['status'] = status;
    }

    if (profilePic != null) {
      json['profilePic'] = profilePic;
    }

    if (languages != null) {
      json['languages'] = languages;
    }

    if (workingDays != null) {
      json['workingDays'] = workingDays!.map((d) => d.toJson()).toList();
    }

    if (onlineSchedule != null) {
      json['onlineSchedule'] = onlineSchedule!.map((d) => d.toJson()).toList();
    }

    if (suspensionReason != null) {
      json['suspensionReason'] = suspensionReason;
    }

    if (suspendedAt != null) {
      json['suspendedAt'] = suspendedAt!.toIso8601String();
    }

    return json;
  }

  // Legacy summary used by views that still display a single fee.
  double get fee => offlineFee;
}
