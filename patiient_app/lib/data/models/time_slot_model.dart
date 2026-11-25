import 'package:flutter/material.dart';

class TimeSlotModel {
  final int slotId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isBooked;
  final String? bookedBy;

  TimeSlotModel({
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.bookedBy,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      slotId: json['slotId'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isBooked: json['isBooked'] as bool? ?? false,
      bookedBy: json['bookedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      if (bookedBy != null) 'bookedBy': bookedBy,
    };
  }

  @override
  String toString() => '$startTime - $endTime';

  Color get statusColor {
    if (isBooked) {
      return const Color(0xFFEF4444); // Red for booked
    }
    return const Color(0xFF22C55E); // Green for available
  }
}
