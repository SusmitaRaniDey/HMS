import 'doctor_model.dart';

class AppointmentModel {
  final int id;
  final int? doctorId;
  final int? patientId;
  final String date;
  final int? serialNumber;
  final String status;
  final String? cancellationReason;
  final DoctorModel? doctor;
  final Map<String, dynamic>? patient;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Payment fields
  final String? paymentMethod;
  final String? paymentStatus;
  final String? isPaid;
  final String? transactionId;
  final String? bankTransactionId;
  final double? paidAmount;

  // Online appointment fields
  final String type; // 'online' | 'offline'
  final String? zoomMeetingId;
  final String? zoomJoinUrl;
  final String? zoomStartUrl;
  final String? zoomPassword;
  String? meetingStatus; // 'scheduled' | 'started' | 'ended'
  final String? startTime; // ISO datetime
  final String? timeSlot;
  final int? prescriptionId;

  // Appointment for another patient fields
  final String? appointmentFor; // 'me' | 'other'
  final String? otherPatientName;
  final int? otherPatientAge;
  final String? otherPatientGender;
  final String? otherPatientContact;

  AppointmentModel({
    required this.id,
    this.doctorId,
    this.patientId,
    required this.date,
    this.serialNumber,
    required this.status,
    this.cancellationReason,
    this.doctor,
    this.patient,
    this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.paymentStatus,
    this.isPaid,
    this.transactionId,
    this.bankTransactionId,
    this.paidAmount,
    this.type = 'offline',
    this.zoomMeetingId,
    this.zoomJoinUrl,
    this.zoomStartUrl,
    this.zoomPassword,
    this.meetingStatus,
    this.startTime,
    this.timeSlot,
    this.prescriptionId,
    this.appointmentFor,
    this.otherPatientName,
    this.otherPatientAge,
    this.otherPatientGender,
    this.otherPatientContact,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      doctorId: json['doctorId'] as int?,
      patientId: json['patientId'] as int?,
      date: json['date'] as String? ?? '',
      serialNumber: json['serialNumber'] as int?,
      status: json['status'] as String? ?? 'pending',
      cancellationReason: json['cancellationReason'] as String?,
      doctor: json['doctor'] != null
          ? DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      patient: json['patient'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      isPaid: json['isPaid'] as String?,
      transactionId: json['transactionId'] as String?,
      bankTransactionId: json['bankTransactionId'] as String?,
      paidAmount: json['paidAmount'] is String
          ? double.tryParse(json['paidAmount'] as String)
          : (json['paidAmount'] as num?)?.toDouble(),
      type: json['type'] as String? ?? 'offline',
      zoomMeetingId: json['zoomMeetingId'] as String?,
      zoomJoinUrl: json['zoomJoinUrl'] as String?,
      zoomStartUrl: json['zoomStartUrl'] as String?,
      zoomPassword: json['zoomPassword'] as String?,
      meetingStatus: json['meetingStatus'] as String?,
      startTime: json['startTime'] as String?,
      timeSlot: (json['timeSlot'] ?? json['time_slot']) as String?,
      prescriptionId: json['prescriptionId'] as int?,
      appointmentFor: json['appointmentFor'] as String?,
      otherPatientName: json['otherPatientName'] as String?,
      otherPatientAge: json['otherPatientAge'] as int?,
      otherPatientGender: json['otherPatientGender'] as String?,
      otherPatientContact: json['otherPatientContact'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (doctorId != null) 'doctorId': doctorId,
    if (patientId != null) 'patientId': patientId,
    'date': date,
    if (serialNumber != null) 'serialNumber': serialNumber,
    'status': status,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
    if (doctor != null) 'doctor': doctor!.toJson(),
    if (patient != null) 'patient': patient,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    if (paymentStatus != null) 'paymentStatus': paymentStatus,
    if (isPaid != null) 'isPaid': isPaid,
    if (transactionId != null) 'transactionId': transactionId,
    if (bankTransactionId != null) 'bankTransactionId': bankTransactionId,
    if (paidAmount != null) 'paidAmount': paidAmount,
    'type': type,
    if (zoomMeetingId != null) 'zoomMeetingId': zoomMeetingId,
    if (zoomJoinUrl != null) 'zoomJoinUrl': zoomJoinUrl,
    if (zoomStartUrl != null) 'zoomStartUrl': zoomStartUrl,
    if (zoomPassword != null) 'zoomPassword': zoomPassword,
    if (meetingStatus != null) 'meetingStatus': meetingStatus,
    if (startTime != null) 'startTime': startTime,
    if (timeSlot != null) 'timeSlot': timeSlot,
    if (prescriptionId != null) 'prescriptionId': prescriptionId,
    if (appointmentFor != null) 'appointmentFor': appointmentFor,
    if (otherPatientName != null) 'otherPatientName': otherPatientName,
    if (otherPatientAge != null) 'otherPatientAge': otherPatientAge,
    if (otherPatientGender != null) 'otherPatientGender': otherPatientGender,
    if (otherPatientContact != null) 'otherPatientContact': otherPatientContact,
  };

  // Status helpers
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get canCancel => (isPending || isConfirmed) && !isAppointmentPast;

  // Online meeting helpers
  bool get isOnline => type == 'online';
  bool get hasMeeting => zoomMeetingId != null && zoomMeetingId!.isNotEmpty;
  bool get meetingEnded => meetingStatus == 'ended';
  bool get meetingStarted => meetingStatus == 'started';
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

  /// Backend still validates every join request; this only controls the button.
  bool get canJoinMeeting {
    final meetingAlreadyHandled =
        ['started', 'ended'].contains(meetingStatus?.toLowerCase()) ||
        isCompleted ||
        isCancelled;
    return isOnline && hasMeeting && !meetingAlreadyHandled && isAppointmentToday;
  }

  // Payment helpers
  bool get isPayNow => paymentMethod?.toLowerCase() == 'pay_now';
  bool get isPayInHospital => paymentMethod?.toLowerCase() == 'pay_in_hospital';
  bool get isPaymentCompleted => paymentStatus?.toLowerCase() == 'completed';
  bool get isPaymentPending => paymentStatus?.toLowerCase() == 'pending';
  bool get isPaymentFailed => paymentStatus?.toLowerCase() == 'failed';
  bool get isPaidStatus => isPaid?.toLowerCase() == 'paid';
  bool get isUnpaidStatus => isPaid?.toLowerCase() == 'unpaid';

  String get paymentMethodDisplay {
    if (isPayNow) return 'Paid Online';
    if (isPayInHospital) return 'Pay at Hospital';
    return 'N/A';
  }

  String get paymentStatusDisplay {
    if (isPaymentCompleted) return 'Completed';
    if (isPaymentPending) return 'Pending';
    if (isPaymentFailed) return 'Failed';
    return 'N/A';
  }

  String get isPaidDisplay {
    if (isPaidStatus) return 'Paid';
    if (isUnpaidStatus) return 'Unpaid';
    return 'N/A';
  }
}
