import 'patient_model.dart';

class AppointmentModel {
  final int id;
  final String date;
  final String? timeSlot;
  final String status;
  final String? cancellationReason;
  final String? rejectionReason;
  final PatientModel? patient;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Online appointment fields
  final String type;
  final String? zoomMeetingId;
  final String? zoomJoinUrl;
  final String? zoomStartUrl;
  final String? zoomPassword;
  String? meetingStatus;
  final String? startTime;
  final int? prescriptionId;
  final int? doctorId;
  final int? patientId;

  AppointmentModel({
    required this.id,
    required this.date,
    this.timeSlot,
    required this.status,
    this.cancellationReason,
    this.rejectionReason,
    this.patient,
    this.createdAt,
    this.updatedAt,
    this.type = 'offline',
    this.zoomMeetingId,
    this.zoomJoinUrl,
    this.zoomStartUrl,
    this.zoomPassword,
    this.meetingStatus,
    this.startTime,
    this.prescriptionId,
    this.doctorId,
    this.patientId,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: _parseId(json['id']),
      date: json['date'] as String? ?? '',
      timeSlot: (json['time_slot'] ?? json['timeSlot']) as String?,
      status: json['status'] as String? ?? 'pending',
      cancellationReason: json['cancellationReason'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      patient: json['patient'] != null
          ? PatientModel.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      type: json['type'] as String? ?? 'offline',
      zoomMeetingId: json['zoomMeetingId'] as String?,
      zoomJoinUrl: json['zoomJoinUrl'] as String?,
      zoomStartUrl: json['zoomStartUrl'] as String?,
      zoomPassword: json['zoomPassword'] as String?,
      meetingStatus: json['meetingStatus'] as String?,
      startTime: json['startTime'] as String?,
      prescriptionId: json['prescriptionId'] as int?,
      doctorId: json['doctorId'] as int?,
      patientId: json['patientId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    if (timeSlot != null) 'time_slot': timeSlot,
    'status': status,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (patient != null) 'patient': patient!.toJson(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'type': type,
    if (zoomMeetingId != null) 'zoomMeetingId': zoomMeetingId,
    if (zoomStartUrl != null) 'zoomStartUrl': zoomStartUrl,
    if (prescriptionId != null) 'prescriptionId': prescriptionId,
  };

  // Status helpers
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isRejected => status.toLowerCase() == 'rejected';

  // Action helpers
  bool get canAccept => isPending;
  bool get canReject => isPending;
  bool get canComplete => isConfirmed;

  // Online meeting helpers
  bool get isOnline => type == 'online';
  bool get hasMeeting => zoomMeetingId != null && zoomMeetingId!.isNotEmpty;
  bool get meetingEnded => meetingStatus == 'ended';
  DateTime? get appointmentDateOnly {
    final appointmentDate = DateTime.tryParse(date);
    if (appointmentDate == null) return null;
    return DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
  }

  bool get isAppointmentToday {
    final appointmentDate = appointmentDateOnly;
    if (appointmentDate == null) return false;
    final today = DateTime.now();
    return appointmentDate.year == today.year &&
        appointmentDate.month == today.month &&
        appointmentDate.day == today.day;
  }

  bool get isAppointmentPast {
    final appointmentDate = appointmentDateOnly;
    if (appointmentDate == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return appointmentDate.isBefore(todayOnly);
  }

  /// Doctor can write prescription after the consultation is confirmed or done.
  bool get canWritePrescription =>
      (isConfirmed || isCompleted || meetingEnded) && prescriptionId == null;

  /// Doctor can start the meeting if it's scheduled and has not already started/ended.
  bool get canStartMeeting {
    final meetingAlreadyHandled =
        ['started', 'ended'].contains(meetingStatus?.toLowerCase()) ||
        isCompleted ||
        isCancelled;
    return isOnline && hasMeeting && !meetingAlreadyHandled && isAppointmentToday;
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
