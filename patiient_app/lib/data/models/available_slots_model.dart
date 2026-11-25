class AvailableSlotsModel {
  final int doctorId;
  final String date;
  final String dayOfWeek;
  final String workingHours;
  final int availableSlots;
  final int consultLimitPerDay;
  final int bookedCount;

  AvailableSlotsModel({
    required this.doctorId,
    required this.date,
    required this.dayOfWeek,
    required this.workingHours,
    required this.availableSlots,
    required this.consultLimitPerDay,
    required this.bookedCount,
  });

  factory AvailableSlotsModel.fromJson(Map<String, dynamic> json) {
    return AvailableSlotsModel(
      doctorId: json['doctorId'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      workingHours: json['workingHours'] as String? ?? '',
      availableSlots: json['availableSlots'] as int? ?? 0,
      consultLimitPerDay: json['consultLimitPerDay'] as int? ?? 0,
      bookedCount: json['bookedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'date': date,
      'dayOfWeek': dayOfWeek,
      'workingHours': workingHours,
      'availableSlots': availableSlots,
      'consultLimitPerDay': consultLimitPerDay,
      'bookedCount': bookedCount,
    };
  }

  bool get hasAvailableSlots => availableSlots > 0;
  String get bookedPercentage => '${(bookedCount / consultLimitPerDay * 100).toStringAsFixed(1)}%';
}
