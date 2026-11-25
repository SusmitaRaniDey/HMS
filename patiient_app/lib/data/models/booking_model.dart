import 'diagnostic_model.dart';

class BookingModel {
  final int id;
  final String scheduleDate;
  final String status;
  final String? notes;
  final String? cancellationReason;
  final DiagnosticModel? diagnostic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Payment fields
  final String? paymentMethod; // 'pay_now' or 'pay_in_hospital'
  final String? paymentStatus; // 'pending', 'completed', 'failed'
  final String? isPaid; // 'paid' or 'unpaid'
  final String? transactionId;
  final String? bankTransactionId;
  final double? paidAmount;

  BookingModel({
    required this.id,
    required this.scheduleDate,
    required this.status,
    this.notes,
    this.cancellationReason,
    this.diagnostic,
    this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.paymentStatus,
    this.isPaid,
    this.transactionId,
    this.bankTransactionId,
    this.paidAmount,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      scheduleDate: json['scheduleDate'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      diagnostic: json['diagnostic'] != null
          ? DiagnosticModel.fromJson(json['diagnostic'] as Map<String, dynamic>)
          : null,
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
          ? double.tryParse(json['paidAmount'])
          : (json['paidAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleDate': scheduleDate,
      'status': status,
      if (notes != null) 'notes': notes,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (diagnostic != null) 'diagnostic': diagnostic!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (isPaid != null) 'isPaid': isPaid,
      if (transactionId != null) 'transactionId': transactionId,
      if (bankTransactionId != null) 'bankTransactionId': bankTransactionId,
      if (paidAmount != null) 'paidAmount': paidAmount,
    };
  }

  // Helper getters
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  DateTime? get scheduleDateOnly {
    final date = DateTime.tryParse(scheduleDate);
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  bool get isScheduleDatePast {
    final date = scheduleDateOnly;
    if (date == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayOnly);
  }

  bool get canCancel => (isPending || isConfirmed) && !isScheduleDatePast;

  // Payment helper getters
  bool get isPayNow => paymentMethod?.toLowerCase() == 'pay_now';
  bool get isPayInHospital => paymentMethod?.toLowerCase() == 'pay_in_hospital';
  bool get isPaymentCompleted => paymentStatus?.toLowerCase() == 'completed';
  bool get isPaymentPending => paymentStatus?.toLowerCase() == 'pending';
  bool get isPaymentFailed => paymentStatus?.toLowerCase() == 'failed';

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

  // Paid/Unpaid helper getters
  bool get isPaidStatus => isPaid?.toLowerCase() == 'paid';
  bool get isUnpaidStatus => isPaid?.toLowerCase() == 'unpaid';

  String get isPaidDisplay {
    if (isPaidStatus) return 'Paid';
    if (isUnpaidStatus) return 'Unpaid';
    return 'N/A';
  }
}
