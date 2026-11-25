import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';

/// SSLCommerz gateway shared with the patient booking flow.
class PaymentService {
  static const _storeId = 'softj696e1f47e866b';
  static const _storePassword = 'softj696e1f47e866b@ssl';

  Future<SSLCTransactionInfoModel?> pay({
    required double amount,
    required String transactionId,
  }) async {
    try {
      return await Sslcommerz(
        initializer: SSLCommerzInitialization(
          ipn_url: 'www.ipnurl.com',
          multi_card_name: 'visa,master,bkash,nagad,rocket',
          currency: SSLCurrencyType.BDT,
          product_category: 'HealthGrid',
          sdkType: SSLCSdkType.TESTBOX,
          store_id: _storeId,
          store_passwd: _storePassword,
          total_amount: amount,
          tran_id: transactionId,
        ),
      ).payNow();
    } catch (_) {
      return null;
    }
  }

  bool succeeded(SSLCTransactionInfoModel? result) {
    final status = result?.status?.toLowerCase();
    return status == 'valid' || status == 'validated';
  }
}
