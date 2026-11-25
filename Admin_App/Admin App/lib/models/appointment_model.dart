class AppointmentModel {
  final int id;
  final int doctorId;
  final int patientId;
  final String doctorName;
  final String doctorSpecialty;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final String date;
  final String status;
  final String type;
  final int? serialNumber;
  final double? fee;
  final String? cancellationReason;
  final String? zoomMeetingId;
  final String? zoomJoinUrl;
  final String? zoomStartUrl;
  final String? zoomPassword;
  final String? meetingStatus;
  final String? startTime;
  final String? timeSlot;
  final int? prescriptionId;

  // Payment fields
  final String isPaid;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? transactionId;
  final String? bankTransactionId;
  final double? paidAmount;

  // Appointment for another patient fields
  final String? appointmentFor;
  final String? otherPatientName;
  final int? otherPatientAge;
  final String? otherPatientGender;
  final String? otherPatientContact;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.patientName,
    required this.patientPhone,
    required this.date,
    required this.status,
    required this.patientEmail,
    this.type = 'offline',
    this.serialNumber,
    this.fee,
    this.cancellationReason,
    this.zoomMeetingId,
    this.zoomJoinUrl,
    this.zoomStartUrl,
    this.zoomPassword,
    this.meetingStatus,
    this.startTime,
    this.timeSlot,
    this.prescriptionId,
    this.isPaid = 'unpaid',
    this.paymentMethod,
    this.paymentStatus,
    this.transactionId,
    this.bankTransactionId,
    this.paidAmount,
    this.appointmentFor,
    this.otherPatientName,
    this.otherPatientAge,
    this.otherPatientGender,
    this.otherPatientContact,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      doctorId: json['doctor']?['id'] ?? 0,
      doctorName: json['doctor']?['name'] ?? 'Unknown Doctor',
      doctorSpecialty: json['doctor']?['specialty'] ?? 'General',
      patientId: json['patient']?['id'] ?? 0,
      patientName: json['patient']?['name'] ?? 'Unknown Patient',
      patientPhone: json['patient']?['phone'] ?? 'N/A',
      patientEmail: json['patient']?['email'] ?? 'N/A',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      type: json['type'] ?? 'offline',
      serialNumber: json['serialNumber'],
      fee: json['doctor']?['fee']?.toDouble(),
      cancellationReason: json['cancellationReason'],
      zoomMeetingId: json['zoomMeetingId'],
      zoomJoinUrl: json['zoomJoinUrl'],
      zoomStartUrl: json['zoomStartUrl'],
      zoomPassword: json['zoomPassword'],
      meetingStatus: json['meetingStatus'],
      startTime: json['startTime'],
      timeSlot: json['timeSlot'] as String?,
      prescriptionId: json['prescriptionId'],
      isPaid: json['isPaid'] as String? ?? 'unpaid',
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      transactionId: json['transactionId'] as String?,
      bankTransactionId: json['bankTransactionId'] as String?,
      paidAmount: json['paidAmount'] is String
          ? double.tryParse(json['paidAmount'] as String)
          : (json['paidAmount'] as num?)?.toDouble(),
      appointmentFor: json['appointmentFor'] as String?,
      otherPatientName: json['otherPatientName'] as String?,
      otherPatientAge: json['otherPatientAge'] as int?,
      otherPatientGender: json['otherPatientGender'] as String?,
      otherPatientContact: json['otherPatientContact'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'date': date,
      'status': status,
      'type': type,
      if (startTime != null) 'startTime': startTime,
      if (timeSlot != null) 'timeSlot': timeSlot,
    };
  }

  // Helper method to check if appointment can be modified
  bool get canBeModified => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isOnline => type == 'online';
  bool get hasMeeting => zoomJoinUrl != null && zoomJoinUrl!.isNotEmpty;

  // Payment helpers
  bool get isPaidStatus => isPaid.toLowerCase() == 'paid';
  String get isPaidDisplay => isPaidStatus ? 'Paid' : 'Unpaid';

  // Get the actual patient name (registered or other)
  String get actualPatientName {
    final otherName = otherPatientName?.trim();
    if (appointmentFor?.toLowerCase() == 'other' &&
        otherName != null &&
        otherName.isNotEmpty) {
      return otherName;
    }
    return patientName;
  }

  String get actualPatientContact {
    final otherContact = otherPatientContact?.trim();
    if (appointmentFor?.toLowerCase() == 'other' &&
        otherContact != null &&
        otherContact.isNotEmpty) {
      return otherContact;
    }
    return patientPhone.isNotEmpty ? patientPhone : patientEmail;
  }
}
