class RefundRequestModel {
  final int id;
  final int appointmentId;
  final int patientId;
  final String patientName;
  final String reason;
  final String status;
  final String? patientNote;
  final String? paymentMethod;
  final double? originalAmount;
  final double? refundedAmount;
  final String refundToAccount;
  final String? refundTransactionId;
  final String? rejectionReason;
  final String? requestedAt;

  RefundRequestModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.reason,
    required this.status,
    this.patientNote,
    this.paymentMethod,
    this.originalAmount,
    this.refundedAmount,
    required this.refundToAccount,
    this.refundTransactionId,
    this.rejectionReason,
    this.requestedAt,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>?;
    return RefundRequestModel(
      id: json['id'] as int,
      appointmentId: json['appointmentId'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      patientName: patient?['name'] as String? ?? 'Unknown Patient',
      reason: json['reason'] as String? ?? '',
      status: json['refundStatus'] as String? ?? 'pending',
      patientNote: json['patientNote'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      originalAmount: _toDouble(json['originalAmount']),
      refundedAmount: _toDouble(json['refundedAmount']),
      refundToAccount: json['refundToAccount'] as String? ?? '',
      refundTransactionId: json['refundTransactionId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      requestedAt: json['requestedAt'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  String get reasonLabel {
    switch (reason) {
      case 'patient_cancelled':
        return 'Patient cancelled';
      case 'doctor_no_show':
        return "Doctor didn't join";
      case 'no_consultation':
        return 'No consultation happened';
      default:
        return reason;
    }
  }
}
