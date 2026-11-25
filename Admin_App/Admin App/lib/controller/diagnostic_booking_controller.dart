import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_endpoints.dart';
import '../models/diagnostic_booking_model.dart';
import '../services/api_services.dart';
import '../services/storage_services.dart';
import '../utils/helpers.dart';

class DiagnosticBookingsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();

  final isLoading = false.obs;
  final bookings = <DiagnosticBookingModel>[].obs;
  final filteredBookings = <DiagnosticBookingModel>[].obs;
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;
  final Rxn<DateTime> selectedStartDate = Rxn<DateTime>();
  final Rxn<DateTime> selectedEndDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    loadBookings();
  }

  Future<void> loadBookings() async {
    try {
      isLoading.value = true;

      // Using the correct endpoint for diagnostic bookings
      final response = await _apiService.get(ApiEndpoints.DIAGNOSTIC_BOOKINGS);

      if (response.data != null) {
        // Check if response has pagination structure
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        bookings.value = (data as List)
            .map((json) => DiagnosticBookingModel.fromJson(json))
            .toList();

        // Sort by created date (newest first)
        bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _applyCurrentFilter();
      }
    } catch (e) {
      print('Error loading bookings: $e');
      Helpers.showErrorSnackbar('Error', 'Failed to load diagnostic bookings');
    } finally {
      isLoading.value = false;
    }
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    _applyCurrentFilter();
  }

  void searchBookings(String query) {
    searchQuery.value = query;
    _applyCurrentFilter();
  }

  void filterByDateRange(DateTimeRange? range) {
    selectedStartDate.value = range?.start;
    selectedEndDate.value = range?.end;
    _applyCurrentFilter();
  }

  void clearDateFilter() {
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    _applyCurrentFilter();
  }

  void _applyCurrentFilter() {
    List<DiagnosticBookingModel> result = List.from(bookings);

    // Apply status filter
    if (selectedStatus.value != 'all') {
      result = result
          .where((booking) =>
              booking.status.toLowerCase() == selectedStatus.value.toLowerCase())
          .toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((booking) {
        return booking.patientName.toLowerCase().contains(query) ||
            booking.diagnosticName.toLowerCase().contains(query) ||
            booking.diagnosticCategory.toLowerCase().contains(query) ||
            booking.patientPhone.contains(query);
      }).toList();
    }

    // Apply date range filter
    if (selectedStartDate.value != null && selectedEndDate.value != null) {
      final startDate = DateTime(selectedStartDate.value!.year,
          selectedStartDate.value!.month, selectedStartDate.value!.day);
      final endDate = DateTime(selectedEndDate.value!.year,
          selectedEndDate.value!.month, selectedEndDate.value!.day);

      result = result.where((booking) {
        try {
          final bookingDate = DateTime.parse(booking.scheduleDate);
          final normalizedDate =
              DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

          return !normalizedDate.isBefore(startDate) &&
              !normalizedDate.isAfter(endDate);
        } catch (e) {
          return false;
        }
      }).toList();
    }

    filteredBookings.value = result;
  }

  Future<void> updateBookingStatus(int id, String newStatus) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Update Status',
      message:
          'Are you sure you want to change status to ${newStatus.toUpperCase()}?',
      confirmText: 'Update',
    );

    if (!confirmed) return;

    try {
      // Update locally first for instant UI update
      final bookingIndex = bookings.indexWhere((b) => b.id == id);
      if (bookingIndex != -1) {
        final updatedBooking = DiagnosticBookingModel(
          id: bookings[bookingIndex].id,
          diagnosticId: bookings[bookingIndex].diagnosticId,
          diagnosticName: bookings[bookingIndex].diagnosticName,
          diagnosticCategory: bookings[bookingIndex].diagnosticCategory,
          patientId: bookings[bookingIndex].patientId,
          patientName: bookings[bookingIndex].patientName,
          patientPhone: bookings[bookingIndex].patientPhone,
          scheduleDate: bookings[bookingIndex].scheduleDate,
          status: newStatus,
          notes: bookings[bookingIndex].notes,
          paymentMethod: bookings[bookingIndex].paymentMethod,
          paymentStatus: bookings[bookingIndex].paymentStatus,
          isPaid: bookings[bookingIndex].isPaid,
          transactionId: bookings[bookingIndex].transactionId,
          bankTransactionId: bookings[bookingIndex].bankTransactionId,
          paidAmount: bookings[bookingIndex].paidAmount,
          createdAt: bookings[bookingIndex].createdAt,
          updatedAt: DateTime.now(),
          cancellationReason: bookings[bookingIndex].cancellationReason,
          isPrescribed: bookings[bookingIndex].isPrescribed,
          prescriptionId: bookings[bookingIndex].prescriptionId,
          adminNote: bookings[bookingIndex].adminNote,
        );
        bookings[bookingIndex] = updatedBooking;
        _applyCurrentFilter();
      }

      final response = await _apiService.patch(
        ApiEndpoints.diagnosticBookingById(id),
        data: {'status': newStatus},
      );

      if (response.statusCode == 200) {
        Helpers.showSuccessSnackbar('Success', 'Booking status updated');
      }
    } on DioException catch (e) {
      // Revert on error
      await loadBookings();
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to update status',
      );
    } catch (e) {
      // Revert on unexpected error
      await loadBookings();
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> cancelBooking(int id, String reason) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.diagnosticBookingCancel(id),
        data: {'reason': reason},
      );

      if (response.statusCode == 200) {
        await loadBookings();
        Get.back(); // Close dialog
        Helpers.showSuccessSnackbar(
          'Success',
          'Booking cancelled successfully',
        );
      }
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to cancel booking',
      );
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> approveBooking(int bookingId) async {
    final admin = _storage.getAdmin();
    if (admin == null) {
      Helpers.showErrorSnackbar('Error', 'Admin session expired');
      return;
    }

    final confirmed = await Helpers.showConfirmDialog(
      title: 'Approve Booking',
      message: 'Approve this diagnostic booking?',
      confirmText: 'Approve',
    );
    if (!confirmed) return;

    try {
      await _apiService.patch(
        ApiEndpoints.diagnosticBookingApprove(bookingId),
        data: {'adminId': admin['id'] as int},
      );
      await loadBookings();
      Helpers.showSuccessSnackbar('Success', 'Booking approved');
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to approve booking',
      );
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> rejectBooking(int bookingId, {String? reason}) async {
    final admin = _storage.getAdmin();
    if (admin == null) {
      Helpers.showErrorSnackbar('Error', 'Admin session expired');
      return;
    }

    final confirmed = await Helpers.showConfirmDialog(
      title: 'Reject Booking',
      message: 'Are you sure you want to reject this diagnostic booking?',
      confirmText: 'Reject',
    );
    if (!confirmed) return;

    try {
      await _apiService.patch(
        ApiEndpoints.diagnosticBookingReject(bookingId),
        data: {
          'adminId': admin['id'] as int,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      await loadBookings();
      Get.back();
      Helpers.showSuccessSnackbar('Success', 'Booking rejected');
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to reject booking',
      );
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> deleteBooking(int id) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Delete Booking',
      message: 'Are you sure you want to delete this booking?',
      confirmText: 'Delete',
    );

    if (!confirmed) return;

    try {
      await _apiService.delete(ApiEndpoints.diagnosticBookingById(id));

      await loadBookings();
      Helpers.showSuccessSnackbar('Success', 'Booking deleted successfully');
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to delete booking',
      );
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> bulkUpdateStatus(List<int> ids, String status) async {
    final confirmed = await Helpers.showConfirmDialog(
      title: 'Bulk Update',
      message: 'Update ${ids.length} bookings to ${status.toUpperCase()}?',
      confirmText: 'Update All',
    );

    if (!confirmed) return;

    try {
      final response = await _apiService.post(
        ApiEndpoints.DIAGNOSTIC_BOOKINGS_BULK_STATUS,
        data: {'ids': ids, 'status': status},
      );

      if (response.statusCode == 200) {
        await loadBookings();
        Helpers.showSuccessSnackbar(
          'Success',
          '${ids.length} bookings updated successfully',
        );
      }
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to bulk update',
      );
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'An unexpected error occurred');
    }
  }

  // Get statistics
  int get totalBookings => bookings.length;
  int get pendingCount => bookings.where((b) => b.status == 'pending').length;
  int get confirmedCount =>
      bookings.where((b) => b.status == 'confirmed').length;
  int get completedCount =>
      bookings.where((b) => b.status == 'completed').length;
  int get cancelledCount =>
      bookings.where((b) => b.status == 'cancelled').length;
}
