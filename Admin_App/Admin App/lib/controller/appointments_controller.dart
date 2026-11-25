import 'package:admin_panel_web_app/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../config/api_endpoints.dart';
import '../models/appointment_model.dart';
import '../services/api_services.dart';
import '../utils/helpers.dart';

class AppointmentsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final appointments = <AppointmentModel>[].obs;
  final filteredAppointments = <AppointmentModel>[].obs;
  final selectedStatus = 'all'.obs;
  final selectedAppointmentType = 'all'.obs;
  final searchQuery = ''.obs;
  final Rxn<DateTime> selectedStartDate = Rxn<DateTime>();
  final Rxn<DateTime> selectedEndDate = Rxn<DateTime>();
  final currentPage = 1.obs;
  final pageLimit = 100.obs;
  final totalAppointmentsCount = 0.obs;

  final List<String> statusFilters = [
    'all',
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    try {
      isLoading.value = true;

      final queryParams = {
        'page': currentPage.value,
        'limit': pageLimit.value,
        if (selectedStatus.value != 'all') 'status': selectedStatus.value,
        if (selectedStartDate.value != null)
          'startDate': DateFormat(
            'yyyy-MM-dd',
          ).format(selectedStartDate.value!),
        if (selectedEndDate.value != null)
          'endDate': DateFormat('yyyy-MM-dd').format(selectedEndDate.value!),
      };

      logger.i('📋 Loading appointments with params: $queryParams');

      final response = await _apiService.get(
        ApiEndpoints.APPOINTMENTS,
        queryParameters: queryParams,
      );

      logger.i('✅ API Response Status: ${response.statusCode}');
      logger.i('📊 API Response Data: ${response.data}');

      if (response.data != null) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        logger.i('📁 Extracted data: $data');

        appointments.value = (data as List)
            .map((json) => AppointmentModel.fromJson(json))
            .toList();

        logger.i('✨ Parsed ${appointments.length} appointments');

        if (response.data is Map && response.data.containsKey('total')) {
          totalAppointmentsCount.value = response.data['total'];
        }

        appointments.sort((a, b) => b.date.compareTo(a.date));
        _applyCurrentFilter();
      }
    } catch (e) {
      logger.e('❌ Error loading appointments: $e');
      Helpers.showErrorSnackbar('Error', 'Failed to load appointments');
    } finally {
      isLoading.value = false;
    }
  }

  void filterByDate(DateTime? date) {
    selectedStartDate.value = date;
    selectedEndDate.value = date;
    currentPage.value = 1;
    loadAppointments();
  }

  void filterByDateRange(DateTimeRange? range) {
    selectedStartDate.value = range?.start;
    selectedEndDate.value = range?.end;
    currentPage.value = 1;
    loadAppointments();
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    selectedAppointmentType.value = 'all';
    currentPage.value = 1;
    loadAppointments();
  }

  void searchAppointments(String query) {
    searchQuery.value = query.trim();
    _applyCurrentFilter();
  }

  void filterByAppointmentType(String type) {
    selectedAppointmentType.value = type;
    selectedStatus.value = 'all';
    currentPage.value = 1;
    loadAppointments();
  }

  void _applyCurrentFilter() {
    var filtered = List<AppointmentModel>.from(appointments);

    if (selectedStatus.value != 'all') {
      filtered = filtered
          .where((apt) => apt.status == selectedStatus.value)
          .toList();
    }

    if (selectedAppointmentType.value != 'all') {
      final showOnline = selectedAppointmentType.value == 'online';
      filtered = filtered.where((apt) => apt.isOnline == showOnline).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((apt) {
        return apt.actualPatientName.toLowerCase().contains(query) ||
            apt.doctorName.toLowerCase().contains(query) ||
            apt.actualPatientContact.toLowerCase().contains(query);
      }).toList();
    }

    if (selectedStartDate.value != null && selectedEndDate.value != null) {
      final start = DateTime(
        selectedStartDate.value!.year,
        selectedStartDate.value!.month,
        selectedStartDate.value!.day,
      );
      final end = DateTime(
        selectedEndDate.value!.year,
        selectedEndDate.value!.month,
        selectedEndDate.value!.day,
      );

      filtered = filtered.where((apt) {
        try {
          final appointmentDate = DateTime.parse(apt.date);
          final normalized = DateTime(
            appointmentDate.year,
            appointmentDate.month,
            appointmentDate.day,
          );
          return !normalized.isBefore(start) && !normalized.isAfter(end);
        } catch (_) {
          return true;
        }
      }).toList();
    }

    filteredAppointments.value = filtered;
    filteredAppointments.refresh();
  }

  Future<void> updateAppointmentStatus(int id, String newStatus) async {
    if (![
      'pending',
      'confirmed',
      'completed',
      'cancelled',
    ].contains(newStatus)) {
      Helpers.showErrorSnackbar('Error', 'Invalid status: $newStatus');
      return;
    }

    final confirmed = await Helpers.showConfirmDialog(
      title: 'Update Status',
      message:
          'Are you sure you want to change status to ${newStatus.toUpperCase()}?',
      confirmText: 'Update',
    );

    if (!confirmed) return;

    try {
      logger.i('📝 Updating appointment $id status to $newStatus');

      final response = await _apiService.post(
        ApiEndpoints.APPOINTMENTS_BULK_STATUS,
        data: {
          'ids': [id],
          'status': newStatus,
        },
      );

      logger.i('✅ Status update response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Update the appointment status in the local list immediately
        final index = appointments.indexWhere((apt) => apt.id == id);
        if (index != -1) {
          // Create updated appointment model
          final updatedAppointment = AppointmentModel(
            id: appointments[index].id,
            doctorId: appointments[index].doctorId,
            patientId: appointments[index].patientId,
            doctorName: appointments[index].doctorName,
            doctorSpecialty: appointments[index].doctorSpecialty,
            patientName: appointments[index].patientName,
            patientPhone: appointments[index].patientPhone,
            patientEmail: appointments[index].patientEmail,
            date: appointments[index].date,
            status: newStatus,
            type: appointments[index].type,
            serialNumber: appointments[index].serialNumber,
            fee: appointments[index].fee,
            cancellationReason: appointments[index].cancellationReason,
            zoomMeetingId: appointments[index].zoomMeetingId,
            zoomJoinUrl: appointments[index].zoomJoinUrl,
            zoomStartUrl: appointments[index].zoomStartUrl,
            zoomPassword: appointments[index].zoomPassword,
            meetingStatus: appointments[index].meetingStatus,
            startTime: appointments[index].startTime,
            prescriptionId: appointments[index].prescriptionId,
            isPaid: appointments[index].isPaid,
            paymentMethod: appointments[index].paymentMethod,
            paymentStatus: appointments[index].paymentStatus,
            transactionId: appointments[index].transactionId,
            bankTransactionId: appointments[index].bankTransactionId,
            paidAmount: appointments[index].paidAmount,
            appointmentFor: appointments[index].appointmentFor,
            otherPatientName: appointments[index].otherPatientName,
            otherPatientAge: appointments[index].otherPatientAge,
            otherPatientGender: appointments[index].otherPatientGender,
            otherPatientContact: appointments[index].otherPatientContact,
          );

          // Update the appointment in the main list
          appointments[index] = updatedAppointment;

          // Re-apply the current filter to update filteredAppointments
          // This ensures the appointment is removed/added based on status filter
          _applyCurrentFilter();

          // Force refresh both lists to trigger UI update
          appointments.refresh();
          filteredAppointments.refresh();
          if (newStatus == 'confirmed') {
            await loadAppointments();
          }

          Helpers.showSuccessSnackbar(
            'Success',
            newStatus == 'confirmed'
                ? 'Appointment confirmed and Zoom meeting created'
                : 'Appointment status updated to $newStatus',
          );
        }
      }
    } on DioException catch (e) {
      logger.e('❌ Status update error: ${e.response?.data}');
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to update status',
      );
    } catch (e) {
      logger.e('❌ Unexpected error: $e');
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> cancelAppointment(int id, String reason) async {
    try {
      Helpers.showLoadingDialog();

      final response = await _apiService.post(
        ApiEndpoints.appointmentCancel(id),
        data: {'cancellationReason': reason},
      );

      if (response.statusCode == 200) {
        await loadAppointments();
        Helpers.showSuccessSnackbar('Success', 'Appointment cancelled');
      }
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to cancel appointment',
      );
    } finally {
      Helpers.hideLoadingDialog();
    }
  }

  Future<void> deleteAppointment(int id) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Delete Appointment',
      message: 'Are you sure you want to delete this appointment?',
      confirmText: 'Delete',
    );

    if (!confirmed) return;

    try {
      Helpers.showLoadingDialog();

      await _apiService.delete(ApiEndpoints.appointmentById(id));

      await loadAppointments();
      Helpers.showSuccessSnackbar(
        'Success',
        'Appointment deleted successfully',
      );
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to delete appointment',
      );
    } finally {
      Helpers.hideLoadingDialog();
    }
  }

  Future<bool> rescheduleAppointment(
    int id, {
    required String newDate,
    required int doctorId,
    required String timeSlot,
    String? reason,
  }) async {
    try {
      Helpers.showLoadingDialog();
      final response = await _apiService.patch(
        ApiEndpoints.appointmentReschedule(id),
        data: {
          'doctorId': doctorId,
          'date': newDate,
          'timeSlot': timeSlot,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );
      Helpers.hideLoadingDialog();
      if (response.statusCode == 200) {
        await loadAppointments();
        Helpers.showSuccessSnackbar('Success', 'Appointment rescheduled');
        return true;
      }
      return false;
    } on DioException catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to reschedule appointment',
      );
      return false;
    } catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadRescheduleDoctors() async {
    final response = await _apiService.get(ApiEndpoints.DOCTORS);
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? const []);
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> loadDoctorTimeSlots(
    int doctorId,
    String date,
    String type,
  ) async {
    final response = await _apiService.get(
      ApiEndpoints.doctorTimeSlots(doctorId),
      queryParameters: {'date': date, 'type': type},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> reassignAppointment(int appointmentId, int newDoctorId) async {
    try {
      Helpers.showLoadingDialog();

      final response = await _apiService.patch(
        ApiEndpoints.appointmentReassign(appointmentId),
        data: {'newDoctorId': newDoctorId},
      );

      if (response.statusCode == 200) {
        await loadAppointments();
        Helpers.showSuccessSnackbar(
          'Success',
          'Appointment reassigned successfully',
        );
      }
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to reassign appointment',
      );
    } finally {
      Helpers.hideLoadingDialog();
    }
  }

  int get totalAppointments => appointments.length;
  int get pendingCount =>
      appointments.where((a) => a.status == 'pending').length;
  int get confirmedCount =>
      appointments.where((a) => a.status == 'confirmed').length;
  int get completedCount =>
      appointments.where((a) => a.status == 'completed').length;
  int get cancelledCount =>
      appointments.where((a) => a.status == 'cancelled').length;
}
