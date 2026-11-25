import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_services.dart';
import '../utils/helpers.dart';
import '../models/user_model.dart';
import '../config/api_endpoints.dart';

class UsersController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final users = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;

  // ── Client-side pagination ────────────────────────────────────────────────
  // NOTE: `/admin-auth/users` does not currently support page/limit query
  // params (unlike the diagnostics/medicines endpoints), so this paginates
  // the already-fetched full list in the UI rather than guessing at
  // server-side params that may not exist. If/when the backend adds
  // page/limit support here, this should be switched to server-side
  // pagination matching DiagnosticsController/MedicineController.
  final currentPage = 0.obs;
  static const int itemsPerPage = 10;

  List<UserModel> get paginatedUsers {
    final start = currentPage.value * itemsPerPage;
    if (start >= filteredUsers.length) return [];
    final end = (start + itemsPerPage).clamp(0, filteredUsers.length);
    return filteredUsers.sublist(start, end);
  }

  int get totalPages => filteredUsers.isEmpty
      ? 1
      : (filteredUsers.length / itemsPerPage).ceil();

  void nextPage() {
    if (currentPage.value < totalPages - 1) currentPage.value++;
  }

  void prevPage() {
    if (currentPage.value > 0) currentPage.value--;
  }

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/admin-auth/users');

      if (response.data != null) {
        users.value = (response.data as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
        filteredUsers.value = users;
        currentPage.value = 0;
      }


      // ########## des ##########
      // if (response.data != null) {
      //   final list = (response.data as List)
      // .map((json) => UserModel.fromJson(json))
      // .toList();

      //   list.sort((a, b) => b.id.compareTo(a.id)); 

      // users.value = list;
      // filteredUsers.value = users;
      // }

    } catch (e) {
      print('Error loading users: $e');
      Helpers.showErrorSnackbar('Error', 'Failed to load users');
    } finally {
      isLoading.value = false;
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.value = users;
    } else {
      filteredUsers.value = users.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.phone.contains(query);
      }).toList();
    }
  }

  Future<void> createPatient(Map<String, dynamic> data) async {
    try {
      Helpers.showLoadingDialog();
      final response = await _apiService.post(ApiEndpoints.USERS, data: data);
      Helpers.hideLoadingDialog();

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        await loadUsers();
        Helpers.showSuccessSnackbar('Success', 'Patient added successfully');
      }
    } on DioException catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to add patient',
      );
    } catch (_) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar('Error', 'Failed to add patient');
    }
  }

  Future<void> deleteUser(int id) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Delete User',
      message: 'Are you sure you want to delete this user?',
      confirmText: 'Delete',
    );

    if (!confirmed) return;

    try {
      Helpers.showLoadingDialog();
      await _apiService.delete('/admin-auth/users/$id');
      Helpers.hideLoadingDialog();
      await loadUsers();
      Helpers.showSuccessSnackbar('Success', 'User deleted successfully');
    } on DioException catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to delete user',
      );
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    try {
      Helpers.showLoadingDialog();

      final response = await _apiService.put(
        '/admin-auth/users/$id',
        data: data,
      );

      Helpers.hideLoadingDialog();

      if (response.statusCode == 200) {
        await loadUsers();
        Get.back();
        Helpers.showSuccessSnackbar('Success', 'User updated successfully');
      }
    } on DioException catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to update user',
      );
    }
  }
}
