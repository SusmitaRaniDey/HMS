class RefundRequestModel {
  final int id;
  final int appointmentId;
  final int patientId;
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
    return RefundRequestModel(
      id: json['id'] as int,
      appointmentId:
          json['appointmentId'] as int? ?? json['appointment_id'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      status:
          json['refundStatus'] as String? ??
          json['refund_status'] as String? ??
          'pending',
      patientNote:
          json['patientNote'] as String? ?? json['patient_note'] as String?,
      paymentMethod:
          json['paymentMethod'] as String? ?? json['payment_method'] as String?,
      originalAmount: _toDouble(json['originalAmount'] ?? json['original_amount']),
      refundedAmount: _toDouble(json['refundedAmount'] ?? json['refunded_amount']),
      refundToAccount:
          json['refundToAccount'] as String? ??
          json['refund_to_account'] as String? ??
          '',
      refundTransactionId:
          json['refundTransactionId'] as String? ??
          json['refund_transaction_id'] as String?,
      rejectionReason:
          json['rejectionReason'] as String? ??
          json['rejection_reason'] as String?,
      requestedAt:
          json['requestedAt'] as String? ?? json['requested_at'] as String?,
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
        return 'I cancelled the appointment';
      case 'doctor_no_show':
        return "Doctor didn't join";
      case 'no_consultation':
        return 'No consultation happened';
      default:
        return reason;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'processing':
        return 'Processing';
      case 'refunded':
        return 'Refunded';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}
