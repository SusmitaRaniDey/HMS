import 'package:get/get.dart';

import '../../data/models/doctor_model.dart';
import '../../data/providers/appointment_provider.dart';
import '../../utils/helpers.dart';

class DoctorsController extends GetxController {
  final AppointmentProvider _provider = AppointmentProvider();

  // Observables
  final isLoading = false.obs;
  final doctors = <DoctorModel>[].obs;
  final filteredDoctors = <DoctorModel>[].obs;
  final searchQuery = ''.obs;
  final selectedDepartment = ''.obs;

  @override
  void onInit() {
    super.onInit();
    selectedDepartment.value = _departmentFromArguments(Get.arguments);
    loadDoctors();
  }

  // Load all doctors
  Future<void> loadDoctors() async {
    try {
      isLoading.value = true;
      final result = await _provider.getAllDoctors();
      final List<dynamic> data = result['data'] as List;
      final doctorList = data
          .map((json) => DoctorModel.fromJson(json as Map<String, dynamic>))
          .toList();
      doctors.value = doctorList;
      _applyFilters();
    } catch (e) {
      String errorMessage = e.toString();

      // Check if it's a 403 Forbidden error
      if (errorMessage.contains('403') ||
          errorMessage.toLowerCase().contains('forbidden')) {
        errorMessage =
            'Access denied. Please ensure you have proper permissions to view doctors.';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'Session expired. Please login again.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      }

      Helpers.showErrorSnackbar('Error Loading Doctors', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Search doctors
  void searchDoctors(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void clearDepartmentFilter() {
    selectedDepartment.value = '';
    _applyFilters();
  }

  void _applyFilters() {
    final department = selectedDepartment.value.trim().toLowerCase();
    final query = searchQuery.value.trim().toLowerCase();

    filteredDoctors.value = doctors.where((doctor) {
      final specialty = doctor.specialty.trim().toLowerCase();
      final matchesDepartment = department.isEmpty || specialty == department;
      final matchesSearch =
          query.isEmpty ||
          doctor.name.toLowerCase().contains(query) ||
          specialty.contains(query);

      return matchesDepartment && matchesSearch;
    }).toList();
  }

  String _departmentFromArguments(dynamic arguments) {
    if (arguments is Map) {
      return arguments['department']?.toString().trim() ?? '';
    }
    if (arguments is String) {
      return arguments.trim();
    }
    return '';
  }

  // Refresh doctors list
  Future<void> refreshDoctors() async {
    await loadDoctors();
  }
}
