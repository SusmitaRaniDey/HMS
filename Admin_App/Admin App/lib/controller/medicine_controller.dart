import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../config/api_endpoints.dart';
import '../models/medicine_model.dart';
import '../services/api_services.dart';
import '../utils/helpers.dart';

class MedicineController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final medicines = <MedicineModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final page = 1.obs;
  final pageSize = 10.obs;
  final total = 0.obs;
  final search = ''.obs;
  Timer? _debounce;

  int get totalPages =>
      total.value == 0 ? 1 : (total.value / pageSize.value).ceil();

  @override
  void onInit() {
    super.onInit();
    loadMedicines();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> loadMedicines() async {
    try {
      isLoading.value = true;
      final searching = search.value.trim().isNotEmpty;
      final response = await _api.get(
        searching ? ApiEndpoints.MEDICINE_SEARCH : ApiEndpoints.MEDICINES,
        queryParameters: {
          'page': page.value,
          'limit': pageSize.value,
          if (searching) 'q': search.value.trim(),
        },
      );
      final body = Map<String, dynamic>.from(response.data as Map);
      medicines.assignAll(
        (body['data'] as List? ?? const []).map(
          (item) =>
              MedicineModel.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      );
      total.value = (body['total'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        _message(e, 'Failed to load medicines'),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void searchMedicines(String value) {
    search.value = value;
    page.value = 1;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), loadMedicines);
  }

  void changePageSize(int? value) {
    if (value == null) return;
    pageSize.value = value;
    page.value = 1;
    loadMedicines();
  }

  void previousPage() {
    if (page.value <= 1) return;
    page.value--;
    loadMedicines();
  }

  void nextPage() {
    if (page.value >= totalPages) return;
    page.value++;
    loadMedicines();
  }

  Future<bool> saveMedicine(
    MedicineModel medicine, {
    bool editing = false,
  }) async {
    try {
      isSaving.value = true;
      if (editing) {
        await _api.put(
          ApiEndpoints.medicineBySl(medicine.sl),
          data: medicine.toJson(),
        );
      } else {
        await _api.post(ApiEndpoints.MEDICINES, data: medicine.toJson());
      }
      Get.back();
      Helpers.showSuccessSnackbar(
        'Success',
        editing
            ? 'Medicine updated successfully'
            : 'Medicine added successfully',
      );
      await loadMedicines();
      return true;
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        _message(e, 'Failed to save medicine'),
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteMedicine(MedicineModel medicine) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Delete Medicine',
      message: 'Are you sure you want to delete this medicine?',
      confirmText: 'Yes, Delete',
      cancelText: 'Cancel',
    );
    if (!confirmed) return;
    try {
      await _api.delete(ApiEndpoints.medicineBySl(medicine.sl));
      if (medicines.length == 1 && page.value > 1) page.value--;
      Helpers.showSuccessSnackbar('Success', 'Medicine deleted successfully');
      await loadMedicines();
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        _message(e, 'Failed to delete medicine'),
      );
    }
  }

  String _message(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      return message is List ? message.join(', ') : message.toString();
    }
    return fallback;
  }
}
