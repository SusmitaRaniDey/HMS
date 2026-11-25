import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/api_endpoints.dart';
import '../models/billing_model.dart';
import '../services/api_services.dart';
import '../utils/helpers.dart';

class BillingController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final billings = <BillingModel>[].obs;

  final page = 1.obs;
  final limit = 20.obs;
  final total = 0.obs;

  final billTypeFilter = 'all'.obs;
  final paymentStatusFilter = 'all'.obs;
  final searchQuery = ''.obs;
  final Rxn<DateTime> dateFrom = Rxn<DateTime>();
  final Rxn<DateTime> dateTo = Rxn<DateTime>();

  int get totalPages => (total.value / limit.value).ceil().clamp(1, 999999);

  @override
  void onInit() {
    super.onInit();
    fetchBilling();
  }

  Future<void> fetchBilling() async {
    try {
      isLoading.value = true;

      final query = <String, dynamic>{
        'page': page.value,
        'limit': limit.value,
      };
      if (billTypeFilter.value != 'all') query['billType'] = billTypeFilter.value;
      if (paymentStatusFilter.value != 'all') {
        query['paymentStatus'] = paymentStatusFilter.value;
      }
      if (searchQuery.value.trim().isNotEmpty) {
        query['search'] = searchQuery.value.trim();
      }
      if (dateFrom.value != null) {
        query['dateFrom'] = _dateOnly(dateFrom.value!);
      }
      if (dateTo.value != null) {
        query['dateTo'] = _dateOnly(dateTo.value!);
      }

      final response = await _apiService.get(
        ApiEndpoints.ADMIN_BILLING,
        queryParameters: query,
      );

      final data = response.data;
      billings.value = (data['data'] as List)
          .map((json) => BillingModel.fromJson(json as Map<String, dynamic>))
          .toList();
      total.value = data['total'] ?? billings.length;
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to load billing records',
      );
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void search(String query) {
    searchQuery.value = query;
    page.value = 1;
    fetchBilling();
  }

  void filterByBillType(String billType) {
    billTypeFilter.value = billType;
    page.value = 1;
    fetchBilling();
  }

  void filterByPaymentStatus(String status) {
    paymentStatusFilter.value = status;
    page.value = 1;
    fetchBilling();
  }

  void filterByDateRange(DateTimeRange? range) {
    dateFrom.value = range?.start;
    dateTo.value = range?.end;
    page.value = 1;
    fetchBilling();
  }

  void clearDateFilter() {
    dateFrom.value = null;
    dateTo.value = null;
    page.value = 1;
    fetchBilling();
  }

  void goToPage(int newPage) {
    if (newPage < 1 || newPage > totalPages || newPage == page.value) return;
    page.value = newPage;
    fetchBilling();
  }
}
