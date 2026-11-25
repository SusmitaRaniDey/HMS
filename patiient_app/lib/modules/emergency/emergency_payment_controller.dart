import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../services/storage_service.dart';

class EmergencyPaymentController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final PaymentService _payments = Get.find<PaymentService>();
  final StorageService _storage = Get.find<StorageService>();
  late final Map<String, dynamic> doctor;
  final isPaying = false.obs;
  final error = RxnString();
  String? _transactionId;

  double _amount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get emergencyFee => _amount(doctor['emergencyFee']);
  double get additionalFee => _amount(doctor['additionalEmergencyFee']);
  double get total => emergencyFee + additionalFee;

  @override
  void onInit() {
    super.onInit();
    doctor = Map<String, dynamic>.from(Get.arguments as Map);
  }

  Future<void> payNow() async {
    if (isPaying.value) return;
    isPaying.value = true;
    error.value = null;
    try {
      final patient = _storage.getPatient();
      if (patient == null) throw 'Please sign in again to continue.';
      final intentResponse = await _api.post(
        '/patient/emergency-consultations/payment/initiate',
        data: {'doctorId': doctor['doctorId']},
      );
      final intent = Map<String, dynamic>.from(intentResponse.data);
      _transactionId = intent['transactionId']?.toString();
      final result = await _payments.initiatePayment(
        amount: _amount(intent['amount']),
        transactionId: _transactionId!,
        productName:
            intent['productName']?.toString() ??
            'Emergency Online Consultation',
        customerName: patient['name']?.toString() ?? 'Patient',
        customerEmail: patient['email']?.toString() ?? 'patient@example.com',
        customerPhone: patient['phone']?.toString() ?? '01700000000',
      );
      if (!_payments.isPaymentSuccessful(result)) {
        await _reportUnsuccessful(result);
        Get.offNamed(
          AppRoutes.EMERGENCY_PAYMENT_FAILED,
          arguments: {'doctor': doctor, 'cancelled': _isCancelled(result)},
        );
        return;
      }
      final response = await _api.post(
        '/patient/emergency-consultations/payment/success',
        data: {
          'transactionId': _transactionId,
          'validationId': _payments.getValidationId(result),
          'bankTransactionId': _payments.getBankTransactionId(result),
          'paymentMethod': _payments.getPaymentMethod(result),
        },
      );
      Get.offNamed(
        AppRoutes.EMERGENCY_PAYMENT_SUCCESS,
        arguments: Map<String, dynamic>.from(response.data),
      );
    } catch (e) {
      error.value = e.toString();
    } finally {
      isPaying.value = false;
    }
  }

  bool _isCancelled(SSLCTransactionInfoModel? result) =>
      result == null || result.status?.toLowerCase() == 'cancelled';

  Future<void> _reportUnsuccessful(SSLCTransactionInfoModel? result) async {
    if (_transactionId == null) return;
    try {
      await _api.post(
        '/patient/emergency-consultations/payment/${_isCancelled(result) ? 'cancel' : 'fail'}',
        data: {'transactionId': _transactionId},
      );
    } catch (_) {}
  }
}
