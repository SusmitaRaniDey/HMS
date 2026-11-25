import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../config/api_endpoints.dart';
import '../models/diagnostic_model.dart';
import '../routes/admin_routes.dart';
import '../services/api_services.dart';
import '../services/image_picker_service.dart';
import '../utils/helpers.dart';

class DiagnosticsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final imagePickerService = ImagePickerService();
  final logger = Logger();

  final isLoading = false.obs;
  // Grouped list: one row per item_code (a test panel, e.g. CBC groups many
  // parameter rows that share the same item_code/category/test_name/price).
  // Pagination is server-side and operates on the grouped tests, not the
  // raw parameter rows, so `total` is the number of unique item codes.
  final diagnosticGroups = <DiagnosticGroupModel>[].obs;
  final filteredDiagnosticGroups = <DiagnosticGroupModel>[].obs;
  final page = 1.obs;
  final pageSize = 10.obs;
  final total = 0.obs;
  final totalParameters = 0.obs;
  final search = ''.obs;
  Timer? _debounce;

  int get totalPages => total.value == 0 ? 1 : (total.value / pageSize.value).ceil();

  // Parameter rows for whichever item_code is currently drilled into.
  final isLoadingParameters = false.obs;
  final parameterRows = <DiagnosticModel>[].obs;

  // Add/Edit Diagnostic Form Controllers
  final testNameController = TextEditingController();
  final categoryController = TextEditingController();
  final itemCodeController = TextEditingController();
  final priceController = TextEditingController();
  final parameterController = TextEditingController();
  final normalRangeController = TextEditingController();
  final unitController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDiagnostics();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    testNameController.dispose();
    categoryController.dispose();
    itemCodeController.dispose();
    priceController.dispose();
    parameterController.dispose();
    normalRangeController.dispose();
    unitController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void clearForm() {
    testNameController.clear();
    categoryController.clear();
    itemCodeController.clear();
    priceController.clear();
    parameterController.clear();
    normalRangeController.clear();
    unitController.clear();
    notesController.clear();
    imagePickerService.clearImage();
  }

  Future<void> loadDiagnostics() async {
    try {
      isLoading.value = true;

      final response = await _apiService.get(
        ApiEndpoints.DIAGNOSTICS_GROUPED,
        queryParameters: {
          'page': page.value,
          'limit': pageSize.value,
          if (search.value.trim().isNotEmpty) 'search': search.value.trim(),
        },
      );

      if (response.data != null) {
        final body = Map<String, dynamic>.from(response.data as Map);
        final groups = (body['data'] as List? ?? const [])
            .map((json) => DiagnosticGroupModel.fromJson(json))
            .toList();
        diagnosticGroups.value = groups;
        filteredDiagnosticGroups.value = groups;
        total.value = (body['total'] as num?)?.toInt() ?? groups.length;
        totalParameters.value = (body['totalParameters'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      print('Error loading diagnostics: $e');
      Helpers.showErrorSnackbar('Error', 'Failed to load diagnostic tests');
    } finally {
      isLoading.value = false;
    }
  }

  void changePageSize(int? value) {
    if (value == null) return;
    pageSize.value = value;
    page.value = 1;
    loadDiagnostics();
  }

  void previousPage() {
    if (page.value <= 1) return;
    page.value--;
    loadDiagnostics();
  }

  void nextPage() {
    if (page.value >= totalPages) return;
    page.value++;
    loadDiagnostics();
  }

  Future<void> loadParametersByItemCode(String itemCode) async {
    try {
      isLoadingParameters.value = true;

      final response = await _apiService.get(
        ApiEndpoints.diagnosticsByItemCode(itemCode),
      );

      if (response.data != null) {
        parameterRows.value = (response.data as List)
            .map((json) => DiagnosticModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading diagnostic parameters: $e');
      Helpers.showErrorSnackbar('Error', 'Failed to load test parameters');
    } finally {
      isLoadingParameters.value = false;
    }
  }

  Future<void> createDiagnostic(DiagnosticModel diagnostic) async {
    try {
      // Helpers.showLoadingDialog();

      // Upload image to Cloudinary if selected
      String? imageUrl;
      if (imagePickerService.selectedImage.value != null) {
        imageUrl = await imagePickerService.uploadImageToCloudinary();
        if (imageUrl == null) {
          logger.w(
            '⚠️ Diagnostic image upload failed. Creating diagnostic without image.',
          );
          Helpers.showErrorSnackbar(
            'Warning',
            'Image upload failed. Test will be added without an image.',
          );
        }
      }

      // Prepare diagnostic data
      final diagnosticData = {
        'test_name': diagnostic.testName,
        'category': diagnostic.category,
        if (diagnostic.itemCode != null && diagnostic.itemCode!.isNotEmpty)
          'item_code': diagnostic.itemCode,
        if (diagnostic.price != null) 'price': diagnostic.price,
        if (diagnostic.parameter != null && diagnostic.parameter!.isNotEmpty)
          'parameter': diagnostic.parameter,
        if (diagnostic.normalRange != null &&
            diagnostic.normalRange!.isNotEmpty)
          'normal_range': diagnostic.normalRange,
        if (diagnostic.unit != null && diagnostic.unit!.isNotEmpty)
          'unit': diagnostic.unit,
        if (diagnostic.notes != null && diagnostic.notes!.isNotEmpty)
          'notes': diagnostic.notes,
        if (imageUrl != null) 'image': imageUrl,
      };
      // Helpers.showLoadingDialog();

      final response = await _apiService.post(
        ApiEndpoints.DIAGNOSTICS,
        data: diagnosticData,
      );
      // Helpers.hideLoadingDialog();

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Helpers.hideLoadingDialog();
        clearForm(); // Clear form before navigating back
        Get.back(); // Close form
        Get.back(); // Close form
        Helpers.showSuccessSnackbar('Success', 'Test added successfully');
        await loadDiagnostics(); // Reload in background
      }
    } on DioException catch (e) {
      // Helpers.hideLoadingDialog();
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ??
                e.response?.data['error'] ??
                'Failed to add test')
          : 'Failed to add test';
      Helpers.showErrorSnackbar('Error', errorMessage);
    } catch (e) {
      // Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> updateDiagnostic(int id, DiagnosticModel diagnostic) async {
    try {
      Helpers.showLoadingDialog();

      // ✅ FIX: Use PATCH method and correct endpoint
      final response = await _apiService.patch(
        ApiEndpoints.diagnosticById(id),
        data: diagnostic.toJson(),
      );

      if (response.statusCode == 200) {
        await loadDiagnostics();
        // Pop back to the diagnostics list without tearing down its route
        // (unlike Get.offAllNamed, this keeps the list's DiagnosticsController
        // alive, so the shared form TextEditingControllers aren't disposed
        // while the edit screen's fields are still transitioning off-screen).
        Get.until((route) => route.settings.name == AdminRoutes.DIAGNOSTICS);
        Helpers.showSuccessSnackbar('Success', 'Test updated successfully');
      }
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to update test',
      );
    } finally {
      Helpers.hideLoadingDialog();
    }
  }

  // Deletes a single parameter row (used from the parameter detail screen).
  // Caller is responsible for refreshing whichever list it's showing.
  Future<bool> deleteDiagnostic(int id) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Delete Parameter',
      message: 'Are you sure you want to delete this parameter row?',
      confirmText: 'Delete',
    );

    if (!confirmed) return false;

    try {
      Helpers.showLoadingDialog();

      await _apiService.delete(ApiEndpoints.diagnosticById(id));

      Helpers.showSuccessSnackbar('Success', 'Parameter deleted successfully');
      return true;
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to delete parameter',
      );
      return false;
    } finally {
      Helpers.hideLoadingDialog();
    }
  }

  void searchDiagnostics(String query) {
    search.value = query;
    page.value = 1;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), loadDiagnostics);
  }
}
