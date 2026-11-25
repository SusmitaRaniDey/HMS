class BillingModel {
  final int id;
  final String? invoiceNumber;
  final int patientId;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final int? appointmentId;
  final int? diagnosticBookingId;
  final String billType;
  final double subtotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final String currency;
  final DateTime invoiceDate;
  final String? description;
  final String? doctorName;
  final String? appointmentDate;
  final String? diagnosticTestName;
  final String? diagnosticScheduleDate;

  BillingModel({
    required this.id,
    this.invoiceNumber,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.patientEmail,
    this.appointmentId,
    this.diagnosticBookingId,
    required this.billType,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    required this.currency,
    required this.invoiceDate,
    this.description,
    this.doctorName,
    this.appointmentDate,
    this.diagnosticTestName,
    this.diagnosticScheduleDate,
  });

  factory BillingModel.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>?;
    final appointment = json['appointment'] as Map<String, dynamic>?;
    final diagnosticBooking = json['diagnosticBooking'] as Map<String, dynamic>?;

    return BillingModel(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      patientId: json['patientId'] ?? patient?['id'] ?? 0,
      patientName: patient?['name'] ?? 'Unknown Patient',
      patientPhone: patient?['phone'] ?? '',
      patientEmail: patient?['email'] ?? '',
      appointmentId: json['appointmentId'],
      diagnosticBookingId: json['diagnosticBookingId'],
      billType: json['billType'] ?? 'other',
      subtotal: double.tryParse('${json['subtotal']}') ?? 0,
      discount: double.tryParse('${json['discount']}') ?? 0,
      tax: double.tryParse('${json['tax']}') ?? 0,
      totalAmount: double.tryParse('${json['totalAmount']}') ?? 0,
      paymentMethod: json['paymentMethod'] ?? 'N/A',
      paymentStatus: json['paymentStatus'] ?? 'N/A',
      transactionId: json['transactionId'],
      currency: json['currency'] ?? 'BDT',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : DateTime.now(),
      description: json['description'],
      doctorName: appointment?['doctor']?['name'],
      appointmentDate: appointment?['date'],
      diagnosticTestName: diagnosticBooking?['diagnostic']?['test_name'],
      diagnosticScheduleDate: diagnosticBooking?['scheduleDate'],
    );
  }

  String get billTypeLabel {
    switch (billType) {
      case 'appointment':
        return 'Doctor Appointment';
      case 'online_consultation':
        return 'Online Doctor Consultation';
      case 'emergency_consultation':
        return 'Emergency Doctor Consultation';
      case 'diagnostic_booking':
        return 'Diagnostic Booking';
      default:
        return 'Other';
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'sslcommerz':
        return 'Online Payment';
      case 'pay_in_hospital':
        return 'Pay at Hospital';
      default:
        return paymentMethod;
    }
  }
}
