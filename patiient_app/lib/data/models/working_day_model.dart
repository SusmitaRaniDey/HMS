class WorkingDayModel {
  final String day;
  final String startTime;
  final String endTime;

  WorkingDayModel({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory WorkingDayModel.fromJson(Map<String, dynamic> json) {
    return WorkingDayModel(
      day: json['day'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  String get timeRange => '$startTime - $endTime';
}
