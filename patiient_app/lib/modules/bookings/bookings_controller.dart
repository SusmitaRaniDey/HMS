import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/booking_model.dart';
import '../../data/providers/booking_provider.dart';
import '../../utils/helpers.dart';

class BookingsController extends GetxController {
  final BookingProvider _provider = BookingProvider();

  // Observables
  final isLoading = false.obs;
  final bookings = <BookingModel>[].obs;
  final filteredBookings = <BookingModel>[].obs;
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
    loadBookings();
  }

  // Load all bookings
  Future<void> loadBookings() async {
    try {
      isLoading.value = true;
      final result = await _provider.getBookings();
      final List<dynamic> data = result['data'] as List;
      bookings.value = data
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
      applyFilter(selectedFilter.value);
    } catch (e) {
      String errorMessage = e.toString();
      
      // Check if it's a 403 Forbidden error
      if (errorMessage.contains('403') || errorMessage.toLowerCase().contains('forbidden')) {
        errorMessage = 'Access denied. Please ensure you have proper permissions to view bookings.';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'Session expired. Please login again.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      }
      
      Helpers.showErrorSnackbar('Error Loading Bookings', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Filter bookings by status
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    if (filter == 'All') {
      filteredBookings.value = bookings;
    } else {
      filteredBookings.value = bookings
          .where((booking) => booking.status.toLowerCase() == filter.toLowerCase())
          .toList();
    }
  }

  // Cancel booking
  Future<void> cancelBooking(int bookingId) async {
    final reasonController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel Booking'),
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
      Helpers.showLoadingDialog(message: 'Cancelling booking...');
      await _provider.cancelBooking(
        bookingId: bookingId,
        reason: reasonController.text.trim(),
      );
      await loadBookings();
      Helpers.hideLoadingDialog();
      Helpers.showSuccessSnackbar('Success', 'Booking cancelled');
    } catch (e) {
      Helpers.hideLoadingDialog();
      debugPrint(e.toString());
      Helpers.showErrorSnackbar('Error', e.toString());
    }
  }

  // Refresh bookings
  Future<void> refreshBookings() async {
    await loadBookings();
  }
}