import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../config/api_endpoints.dart';
import '../models/staff_model.dart';
import '../services/api_services.dart';
import '../utils/helpers.dart';

class StaffController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final staff = <StaffModel>[].obs;
  final filteredStaff = <StaffModel>[].obs;
  final searchQuery = ''.obs;
  final selectedRole = ''.obs;
  final currentPage = 0.obs;
  static const int itemsPerPage = 10;

  @override
  void onInit() {
    super.onInit();
    loadStaff();
  }

  Future<void> loadStaff() async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(ApiEndpoints.STAFF);
      
      if (response.data != null) {
        staff.value = (response.data as List)
            .map((json) => StaffModel.fromJson(json))
            .toList();
        _applyFilters();
      }

      // ########## des ##########
      //  if (response.data != null) {
      //   final list = (response.data as List)
      //       .map((json) => StaffModel.fromJson(json))
      //       .toList();
      // list.sort((a, b) => b.id.compareTo(a.id));
      // staff.value = list;
      // _applyFilters();
      // }

    } 
    catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to load staff');
    } finally {
      isLoading.value = false;
    }
  }

  void searchStaff(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterByRole(String role) {
    selectedRole.value = role;
    _applyFilters();
  }

  void _applyFilters() {
    var result = staff.toList();
    if (selectedRole.value.isNotEmpty) {
      result = result.where((s) => s.role == selectedRole.value).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q) ||
                s.role.toLowerCase().contains(q),
          )
          .toList();
    }
    filteredStaff.value = result;
    currentPage.value = 0;
  }

  List<StaffModel> get paginatedStaff {
    final start = currentPage.value * itemsPerPage;
    if (start >= filteredStaff.length) return [];
    final end = (start + itemsPerPage).clamp(0, filteredStaff.length);
    return filteredStaff.sublist(start, end);
  }

  int get totalPages =>
      filteredStaff.isEmpty ? 1 : (filteredStaff.length / itemsPerPage).ceil();

  void nextPage() {
    if (currentPage.value < totalPages - 1) currentPage.value++;
  }

  void prevPage() {
    if (currentPage.value > 0) currentPage.value--;
  }

  Future<void> createStaff(Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;

      // Backend create DTO does not accept 'role' — extract it first
      final role = data['role'] as String? ?? 'admin';
      final createPayload = {
        'name': data['name'],
        'email': data['email'],
        'phone': data['phone'],
        'password': data['password'],
      };

      final response = await _apiService.post(
        ApiEndpoints.STAFF_CREATE,
        data: createPayload,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newId = response.data['id'] as int?;

        // Assign role — try POST first (backend expects POST), then fall back to PATCH/PUT
        if (newId != null && role != 'admin') {
          bool roleSet = false;
          try {
            await _apiService.post(
              ApiEndpoints.assignRole(newId),
              data: {'role': role},
            );
            roleSet = true;
          } catch (_) {}

          if (!roleSet) {
            try {
              await _apiService.patch(
                ApiEndpoints.assignRole(newId),
                data: {'role': role},
              );
              roleSet = true;
            } catch (_) {}
          }

          if (!roleSet) {
            try {
              await _apiService.put(
                ApiEndpoints.assignRole(newId),
                data: {'role': role},
              );
              roleSet = true;
            } catch (_) {}
          }

          if (!roleSet) {
            await loadStaff();
            Get.back();
            Helpers.showWarningSnackbar(
              'Partial Success',
              'Staff created but role could not be set. Please edit to assign role.',
            );
            return;
          }
        }

        await loadStaff();
        Get.back();
        Helpers.showSuccessSnackbar('Success', 'Staff member added successfully');
      }
    } on DioException catch (e) {
      Helpers.showErrorSnackbar('Error', _extractError(e, 'Failed to add staff'));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> updateStaff(int id, Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;

      // Separate role — it goes through the dedicated assignRole endpoint
      final role = data.remove('role') as String?;

      // Update name / phone / password via PUT
      if (data.isNotEmpty) {
        await _apiService.put(
          ApiEndpoints.staffById(id),
          data: data,
        );
      }

      // Update role separately (backend expects POST for assign-role)
      if (role != null) {
        await _apiService.post(
          ApiEndpoints.assignRole(id),
          data: {'role': role},
        );
      }

      await loadStaff();
      Get.back();
      Helpers.showSuccessSnackbar('Success', 'Staff updated successfully');
    } on DioException catch (e) {
      Helpers.showErrorSnackbar('Error', _extractError(e, 'Failed to update staff'));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteStaff(int id, String name) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Delete Staff',
      message: 'Are you sure you want to delete $name?',
      confirmText: 'Delete',
    );
    if (!confirmed) return;

    try {
      Helpers.showLoadingDialog();
      await _apiService.delete(ApiEndpoints.staffById(id));
      Helpers.hideLoadingDialog();
      await loadStaff();
      Helpers.showSuccessSnackbar('Success', 'Staff deleted successfully');
    } on DioException catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar('Error', _extractError(e, 'Failed to delete staff'));
    }
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      if (data['message'] is String) return data['message'];
      if (data['error'] is String) return data['error'];
    }
    return fallback;
  }
}
