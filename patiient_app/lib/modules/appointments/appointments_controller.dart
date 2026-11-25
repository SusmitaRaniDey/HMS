import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/appointment_model.dart';
import '../../data/providers/appointment_provider.dart';
import '../../utils/helpers.dart';

class AppointmentsController extends GetxController {
  final AppointmentProvider _provider = AppointmentProvider();

  // Observables
  final isLoading = false.obs;
  final appointments = <AppointmentModel>[].obs;
  final filteredAppointments = <AppointmentModel>[].obs;
  final selectedFilter = 'All'.obs;

  final List<String> filters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  // Load all appointments
  Future<void> loadAppointments() async {
    try {
      isLoading.value = true;
      final result = await _provider.getAppointments();
      final List<dynamic> data = result['data'] as List;
     final  appointmentList = data
          .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      appointments.value= appointmentList;
      applyFilter(selectedFilter.value);
    } catch (e) {
      String errorMessage = e.toString();
      
      // Check if it's a 403 Forbidden error
      if (errorMessage.contains('403') || errorMessage.toLowerCase().contains('forbidden')) {
        errorMessage = 'Access denied. Please ensure you have proper permissions to view appointments.';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'Session expired. Please login again.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      }
      
      Helpers.showErrorSnackbar('Error Loading Appointments', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Filter appointments by status
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    if (filter == 'All') {
      filteredAppointments.value = appointments;
    } else {
      filteredAppointments.value = appointments
          .where((apt) => apt.status.toLowerCase() == filter.toLowerCase())
          .toList();
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(int appointmentId) async {
    final reasonController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Cancellation reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) {
      if (confirmed == true && reasonController.text.trim().isEmpty) {
        Helpers.showErrorSnackbar('Error', 'Please provide a reason');
      }
      return;
    }

    try {
      Helpers.showLoadingDialog(message: 'Cancelling appointment...');
      await _provider.cancelAppointment(
        appointmentId: appointmentId,
        reason: reasonController.text.trim(),
      );
      await loadAppointments();
      Helpers.hideLoadingDialog();
      Helpers.showSuccessSnackbar('Success', 'Appointment cancelled');
    } catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar('Error', e.toString());
    }
  }

  // Refresh appointments
  Future<void> refreshAppointments() async {
    await loadAppointments();
  }

  // Get doctor's working hours
  Future<Map<String, dynamic>?> getDoctorSchedule(int doctorId) async {
    try {
      final schedule = await _provider.getDoctorWorkingDays(doctorId);
      return schedule.toJson();
    } catch (e) {
      print('Error fetching doctor schedule: $e');
      return null;
    }
  }
}