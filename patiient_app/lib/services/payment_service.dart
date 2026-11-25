import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class PaymentService {
  final Logger _logger = Logger();

  // Overridable at build time so credentials/environment aren't permanently
  // baked into every build, e.g.:
  //   flutter build apk --dart-define=SSLCOMMERZ_STORE_ID=... \
  //     --dart-define=SSLCOMMERZ_STORE_PASSWORD=... \
  //     --dart-define=IS_SANDBOX=false
  // Defaults preserve the existing sandbox dev credentials when not passed.
  static const String STORE_ID = String.fromEnvironment(
    'SSLCOMMERZ_STORE_ID',
    defaultValue: 'softj696e1f47e866b',
  );
  static const String STORE_PASSWORD = String.fromEnvironment(
    'SSLCOMMERZ_STORE_PASSWORD',
    defaultValue: 'softj696e1f47e866b@ssl',
  );

  // Use sandbox for testing, production for live.
  // Defaults to true (sandbox) so existing dev/test builds keep working;
  // pass --dart-define=IS_SANDBOX=false for a live/production build.
  static const bool IS_SANDBOX = bool.fromEnvironment(
    'IS_SANDBOX',
    defaultValue: true,
  );

  /// Initiate payment with SSLCommerz
  Future<SSLCTransactionInfoModel?> initiatePayment({
    required double amount,
    required String transactionId,
    required String productName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      Sslcommerz sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          // Mandatory fields
          ipn_url: "www.ipnurl.com",
          multi_card_name: "visa,master,bkash,nagad,rocket",
          currency: SSLCurrencyType.BDT,
          product_category: "Diagnostic Test",
          sdkType: IS_SANDBOX ? SSLCSdkType.TESTBOX : SSLCSdkType.LIVE,
          store_id: STORE_ID,
          store_passwd: STORE_PASSWORD,
          total_amount: amount,
          tran_id: transactionId,
        ),
      );

      _logger.i('Initiating SSLCommerz payment for amount: $amount');

      SSLCTransactionInfoModel result = await sslcommerz.payNow();

      _logger.i('Payment result: ${result.status}');

      return result;
    } catch (e) {
      _logger.e('Payment error: $e');
      return null;
    }
  }

  /// Verify payment status
  bool isPaymentSuccessful(SSLCTransactionInfoModel? transactionInfo) {
    if (transactionInfo == null) return false;

    // Check if payment was successful
    // Status can be: VALID, VALIDATED, FAILED, CANCELLED
    return transactionInfo.status?.toLowerCase() == 'valid' ||
        transactionInfo.status?.toLowerCase() == 'validated';
  }

  /// Get transaction ID from payment result
  String? getTransactionId(SSLCTransactionInfoModel? transactionInfo) {
    return transactionInfo?.tranId;
  }

  /// Get bank transaction ID
  String? getBankTransactionId(SSLCTransactionInfoModel? transactionInfo) {
    return transactionInfo?.bankTranId;
  }

  String? getValidationId(SSLCTransactionInfoModel? transactionInfo) =>
      transactionInfo?.valId;

  String getPaymentMethod(SSLCTransactionInfoModel? transactionInfo) {
    final method = transactionInfo?.cardType;
    return method == null || method.isEmpty ? 'sslcommerz' : method;
  }

  /// Generate unique transaction ID
  String generateTransactionId({String prefix = 'DGN'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp';
  }

  /// Show payment status dialog
  void showPaymentStatusDialog({
    required BuildContext context,
    required bool isSuccess,
    required String message,
    VoidCallback? onClose,
  }) {
    Get.dialog(
      AlertDialog(
        title: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess ? 'Payment Successful' : 'Payment Failed',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              onClose?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
