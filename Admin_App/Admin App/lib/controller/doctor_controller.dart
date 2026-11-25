import 'package:admin_panel_web_app/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/api_endpoints.dart';
import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../services/api_services.dart';
import '../services/image_picker_service.dart';
import '../utils/helpers.dart';

class DoctorsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final imagePickerService = ImagePickerService();

  final isLoading = false.obs;
  final doctors = <DoctorModel>[].obs;
  final filteredDoctors = <DoctorModel>[].obs;
  final doctorAppointments = <AppointmentModel>[].obs;
  final doctorsWithAppointments = <DoctorModel>[].obs;
  final isLoadingAppointments = false.obs;
  final isLoadingDoctorsWithAppointments = false.obs;

  // Add/Edit Doctor Form Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final degreesController = TextEditingController();
  final specialtyController = TextEditingController();
  final experienceController = TextEditingController();
  final workingAtController = TextEditingController();
  final onlineFeeController = TextEditingController();
  final offlineFeeController = TextEditingController();
  final biographyController = TextEditingController();
  final languagesController = TextEditingController();
  final consultLimitController = TextEditingController();

  // Working days management
  final workingDays = <DaySchedule>[].obs;
  final onlineSchedule = <OnlineSchedule>[].obs;

  @override
  void onInit() {
    super.onInit();
    consultLimitController.text = '30';
    loadDoctors();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    degreesController.dispose();
    specialtyController.dispose();
    experienceController.dispose();
    workingAtController.dispose();
    onlineFeeController.dispose();
    offlineFeeController.dispose();
    biographyController.dispose();
    languagesController.dispose();
    consultLimitController.dispose();
    super.onClose();
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    degreesController.clear();
    specialtyController.clear();
    experienceController.clear();
    workingAtController.clear();
    onlineFeeController.clear();
    offlineFeeController.clear();
    biographyController.clear();
    languagesController.clear();
    consultLimitController.text = '30';
    workingDays.clear();
    onlineSchedule.clear();
    imagePickerService.clearImage();
  }

  void addWorkingDay(DaySchedule day) {
    final existingIndex = workingDays.indexWhere(
      (item) => item.day.toLowerCase() == day.day.toLowerCase(),
    );
    if (existingIndex >= 0) {
      workingDays[existingIndex] = day;
    } else {
      workingDays.add(day);
    }
  }

  void removeWorkingDay(int index) {
    workingDays.removeAt(index);
  }

  void addOnlineSchedule(OnlineSchedule schedule) {
    final existingIndex = onlineSchedule.indexWhere(
      (item) => item.day.toLowerCase() == schedule.day.toLowerCase(),
    );
    if (existingIndex >= 0) {
      onlineSchedule[existingIndex] = schedule;
    } else {
      onlineSchedule.add(schedule);
    }
  }

  void removeOnlineSchedule(int index) {
    onlineSchedule.removeAt(index);
  }

  Future<void> loadDoctors() async {
    try {
      isLoading.value = true;

      // ✅ Use DOCTORS_WITH_APPOINTMENTS endpoint to get appointment counts
      final response = await _apiService
          .get(ApiEndpoints.DOCTORS_WITH_APPOINTMENTS)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - took more than 30 seconds');
            },
          );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        doctors.value = list.map((json) => DoctorModel.fromJson(json)).toList();
        filteredDoctors.value = doctors;

        //########## Des ##########
        // final list = response.data as List;
        //  final mapped = list.map((json) => DoctorModel.fromJson(json)).toList();
        // mapped.sort((a, b) => b.id!.compareTo(a.id!));
        // doctors.value = mapped;
        // filteredDoctors.value = doctors;

        logger.i('✅ Loaded ${doctors.length} doctors successfully');
      } else {
        Helpers.showErrorSnackbar('Error', 'Failed to load doctors');
      }
    } on DioException catch (e) {
      String errorMsg = 'Failed to load doctors';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Server response timeout';
      }
      Helpers.showErrorSnackbar('Error', errorMsg);
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to load doctors');
    } finally {
      isLoading.value = false;
      logger.i('✅ Loading state reset to false');
    }
  }

  Future<void> createDoctor(DoctorModel doctor) async {
    try {
      isLoading.value = true;
      //Helpers.showLoadingDialog();

      // Upload image to Cloudinary if selected
      String? profilePicUrl;
      if (imagePickerService.selectedImage.value != null) {
        profilePicUrl = await imagePickerService.uploadImageToCloudinary();
        if (profilePicUrl == null) {
          logger.w(
            '⚠️ Profile image upload failed. Creating doctor without profile picture.',
          );
          Helpers.showErrorSnackbar(
            'Warning',
            'Profile image upload failed. Doctor will be added without a picture.',
          );
        }
      }

      // Prepare doctor data
      final doctorData = {
        'name': doctor.name,
        'email': doctor.email,
        'password': doctor.password,
        'phone': doctor.phone,
        'degrees': doctor.degrees,
        'specialty': doctor.specialty,
        'experience': doctor.experience,
        'working_at': doctor.workingAt,
        'fee': doctor.offlineFee,
        'onlineFee': doctor.onlineFee,
        'offlineFee': doctor.offlineFee,
        'biography': doctor.biography,
        'consultLimitPerDay': doctor.consultLimitPerDay ?? 30,
        if (profilePicUrl != null) 'profilePic': profilePicUrl,
        if (doctor.languages != null) 'languages': doctor.languages,
        if (doctor.workingDays != null)
          'workingDays': doctor.workingDays!.map((d) => d.toJson()).toList(),
        if (doctor.onlineSchedule != null)
          'onlineSchedule': doctor.onlineSchedule!
              .map((d) => d.toJson())
              .toList(),
      };

      logger.d('📤 Sending doctor data: $doctorData');

      final response = await _apiService.post(
        ApiEndpoints.DOCTORS,
        data: doctorData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        isLoading.value = false;
        // Helpers.hideLoadingDialog();
        clearForm(); // Clear form before navigating back
        Get.back(); // Close form
        Helpers.showSuccessSnackbar('Success', 'Doctor added successfully');
        loadDoctors(); // Reload in background
      }
    } on DioException catch (e) {
      isLoading.value = false;
      // Helpers.hideLoadingDialog();
      logger.e('❌ DioException: ${e.response?.data}');

      String errorMessage = 'Failed to add doctor';

      if (e.response?.data is Map) {
        final data = e.response!.data as Map;

        // Handle message as array
        if (data['message'] is List) {
          final messages = data['message'] as List;
          errorMessage = messages.isNotEmpty
              ? messages.join(', ')
              : errorMessage;
        }
        // Handle message as string
        else if (data['message'] is String) {
          errorMessage = data['message'];
        }
        // Fallback to error field
        else if (data['error'] is String) {
          errorMessage = data['error'];
        }
      }

      Helpers.showErrorSnackbar('Error', errorMessage);
    } catch (e) {
      isLoading.value = false;
      //Helpers.hideLoadingDialog();
      logger.e('❌ Unexpected error: $e');
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> updateDoctor(int id, DoctorModel doctor) async {
    try {
      Helpers.showLoadingDialog();
      // The dialog overlay is mounted asynchronously. Without this wait, a
      // fast local response can finish before the overlay exists, leaving it
      // visible permanently when it mounts on the following frame.
      await WidgetsBinding.instance.endOfFrame;

      String? profilePicUrl = doctor.profilePic;
      if (imagePickerService.selectedImage.value != null) {
        profilePicUrl = await imagePickerService.uploadImageToCloudinary();
        if (profilePicUrl == null) {
          Helpers.hideLoadingDialog();
          Helpers.showErrorSnackbar(
            'Image upload failed',
            'The doctor was not updated. Please try the image upload again.',
          );
          return;
        }
      }

      final payload = doctor.toJson();
      if (doctor.password.trim().isNotEmpty) {
        payload['password'] = doctor.password.trim();
      }
      if (profilePicUrl != null && profilePicUrl.trim().isNotEmpty) {
        payload['profilePic'] = profilePicUrl;
      }
      logger.d('📤 Update doctor payload: $payload');

      final response = await _apiService.patch(
        ApiEndpoints.doctorById(id),
        data: payload,
      );

      Helpers.hideLoadingDialog();

      if (response.statusCode == 200) {
        await loadDoctors();
        imagePickerService.clearImage();
        final updatedDoctor = doctors.firstWhere(
          (item) => item.id == id,
          orElse: () => doctor,
        );

        // Let the loading-dialog pop finish before replacing the edit route.
        // Calling Get.back immediately here can target the dialog overlay
        // instead of the Edit Doctor page.
        await WidgetsBinding.instance.endOfFrame;
        Get.offNamed('/doctors/detail', arguments: updatedDoctor);
        Helpers.showSuccessSnackbar('Success', 'Doctor updated successfully');
      }
    } on DioException catch (e) {
      Helpers.hideLoadingDialog();
      logger.e('❌ Update doctor response body: ${e.response?.data}');
      String errorMessage = 'Failed to update doctor';
      final data = e.response?.data;
      if (data is Map) {
        if (data['message'] is List) {
          errorMessage = (data['message'] as List).join(', ');
        } else if (data['message'] is String) {
          errorMessage = data['message'];
        } else if (data['error'] is String) {
          errorMessage = data['error'];
        }
      }
      Helpers.showErrorSnackbar('Error', errorMessage);
    } catch (e) {
      Helpers.hideLoadingDialog();
      logger.e('❌ Unexpected error in updateDoctor: $e');
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    } finally {
      Helpers.hideLoadingDialog();
    }
  }

  Future<void> deleteDoctor(int id) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Delete Doctor',
      message: 'Are you sure you want to delete this doctor?',
      confirmText: 'Delete',
    );

    if (!confirmed) return;

    try {
      Helpers.showLoadingDialog();

      await _apiService.delete(ApiEndpoints.doctorById(id));

      await loadDoctors();
      Get.back();
      Helpers.showSuccessSnackbar('Success', 'Doctor deleted successfully');
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to delete doctor',
      );
    } finally {
      Helpers.hideLoadingDialog();
    }
  }

  void searchDoctors(String query) {
    if (query.isEmpty) {
      filteredDoctors.value = doctors;
    } else {
      filteredDoctors.value = doctors.where((doctor) {
        return doctor.name.toLowerCase().contains(query.toLowerCase()) ||
            doctor.specialty.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  /// Fetch appointments for a specific doctor
  Future<void> getDoctorAppointments(int doctorId) async {
    try {
      isLoadingAppointments.value = true;
      doctorAppointments.clear();

      logger.i('📋 Fetching appointments for doctor ID: $doctorId');

      final response = await _apiService.get(
        ApiEndpoints.doctorAppointments(doctorId),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        if (data is! List) {
          logger.w(
            'Unexpected doctor appointments response: ${data.runtimeType}',
          );
          doctorAppointments.clear();
          return;
        }

        final parsedAppointments = <AppointmentModel>[];
        for (final item in data) {
          if (item is! Map) continue;
          try {
            parsedAppointments.add(
              AppointmentModel.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (error) {
            logger.w('Skipping invalid appointment response item: $error');
          }
        }
        doctorAppointments.assignAll(parsedAppointments);

        // Sort by date (most recent first)
        doctorAppointments.sort((a, b) => b.date.compareTo(a.date));

        logger.i(
          '✅ Loaded ${doctorAppointments.length} appointments for doctor $doctorId',
        );
      }
    } catch (e) {
      logger.e('❌ Error loading doctor appointments: $e');
      // Appointments are secondary content on the doctor details page. Keep
      // the page usable (with an empty list) if this auxiliary request fails.
      doctorAppointments.clear();
    } finally {
      isLoadingAppointments.value = false;
    }
  }

  /// Fetch all doctors who have appointments
  Future<void> loadDoctorsWithAppointments() async {
    try {
      isLoadingDoctorsWithAppointments.value = true;

      logger.i('📋 Loading doctors with appointments');

      final response = await _apiService.get(
        ApiEndpoints.DOCTORS_WITH_APPOINTMENTS,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        // Filter to only include doctors with appointments (appointmentsCount > 0)
        doctorsWithAppointments.value = (data as List)
            .map((json) => DoctorModel.fromJson(json))
            .where((doctor) => (doctor.appointmentsCount ?? 0) > 0)
            .toList();

        logger.i(
          '✅ Loaded ${doctorsWithAppointments.length} doctors with appointments',
        );
      }
    } catch (e) {
      logger.e('❌ Error loading doctors with appointments: $e');
      Helpers.showErrorSnackbar(
        'Error',
        'Failed to load doctors with appointments',
      );
    } finally {
      isLoadingDoctorsWithAppointments.value = false;
    }
  }

  // Computed properties for appointment statistics
  int getAppointmentCount(String status) {
    return doctorAppointments.where((apt) => apt.status == status).length;
  }

  int get totalAppointments => doctorAppointments.length;
  int get pendingAppointments => getAppointmentCount('pending');
  int get confirmedAppointments => getAppointmentCount('confirmed');
  int get completedAppointments => getAppointmentCount('completed');
  int get cancelledAppointments => getAppointmentCount('cancelled');

  // Removed complex filtering and sorting logic as per user request
}
