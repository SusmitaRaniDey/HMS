class DoctorScheduleModel {
  final int doctorId;
  final String name;
  final List<dynamic> workingDays;
  final List<dynamic> onlineSchedule;
  final int consultLimitPerDay;

  DoctorScheduleModel({
    required this.doctorId,
    required this.name,
    required this.workingDays,
    required this.onlineSchedule,
    required this.consultLimitPerDay,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleModel(
      doctorId: json['doctorId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      workingDays: json['workingDays'] as List? ?? [],
      onlineSchedule: json['onlineSchedule'] as List? ?? [],
      consultLimitPerDay: json['consultLimitPerDay'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'name': name,
      'workingDays': workingDays,
      'onlineSchedule': onlineSchedule,
      'consultLimitPerDay': consultLimitPerDay,
    };
  }

  List<String> get workingDayNames {
    if (workingDays.isEmpty) return [];
    return workingDays
        .map((day) => (day as Map<String, dynamic>)['day'] as String)
        .toList();
  }

  List<String> get onlineDayNames {
    if (onlineSchedule.isEmpty) return [];
    return onlineSchedule
        .map(
          (slot) =>
              ((slot as Map<String, dynamic>)['day'] ?? slot['date']) as String,
        )
        .toList();
  }
}
