import 'package:get/get.dart';

import '../../config/environment.dart';
import '../../services/api_service.dart';
import '../models/booking_model.dart';
import '../models/diagnostic_model.dart';

class BookingProvider {
  final ApiService _apiService = Get.find<ApiService>();

  // Get All Diagnostics (for browsing before booking) — one entry per
  // unique item_code, matching the Admin Panel's Diagnostics Management.
  Future<Map<String, dynamic>> getAllDiagnostics({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    final response = await _apiService.get(
      Environment.DIAGNOSTICS,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Full detail (including every parameter row) for the test panel with
  // the given item_code — powers the Diagnostic Details screen.
  Future<DiagnosticDetailModel> getDiagnosticByItemCode(String itemCode) async {
    final response = await _apiService.get(
      Environment.diagnosticByItemCode(itemCode),
    );
    return DiagnosticDetailModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // Distinct diagnostic categories, for category filtering.
  Future<List<String>> getDiagnosticCategories() async {
    final response = await _apiService.get(Environment.DIAGNOSTICS_CATEGORIES);
    return (response.data as List).cast<String>();
  }

  // Book Diagnostic Test
  Future<BookingModel> bookDiagnostic({
    required int diagnosticId,
    required String scheduleDate,
    String? status,
    String? notes,
    String? paymentMethod,
    String? paymentStatus,
    String? isPaid,
    String? transactionId,
    String? bankTransactionId,
    double? paidAmount,
    int? prescriptionId,
    bool? isPrescribed,
  }) async {
    final response = await _apiService.post(
      Environment.BOOKINGS,
      data: {
        'diagnosticId': diagnosticId,
        'scheduleDate': scheduleDate,
        if (status != null) 'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (isPaid != null) 'isPaid': isPaid,
        if (transactionId != null) 'transactionId': transactionId,
        if (bankTransactionId != null) 'bankTransactionId': bankTransactionId,
        if (paidAmount != null) 'paidAmount': paidAmount,
        if (prescriptionId != null) 'prescriptionId': prescriptionId,
        if (isPrescribed != null) 'isPrescribed': isPrescribed,
      },
    );

    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Confirms an online payment for a diagnostic booking created above. The
  // booking always starts unpaid/pending server-side regardless of what
  // bookDiagnostic() was told — this is the only call that can actually
  // mark it paid (and auto-confirm it), and the backend independently
  // re-verifies the transaction with SSLCommerz rather than trusting this
  // request.
  Future<BookingModel> confirmDiagnosticPayment({
    required int bookingId,
    required String transactionId,
    String? validationId,
    String? bankTransactionId,
  }) async {
    final response = await _apiService.post(
      '${Environment.BOOKINGS}/$bookingId/confirm-payment',
      data: {
        'transactionId': transactionId,
        if (validationId != null) 'validationId': validationId,
        if (bankTransactionId != null) 'bankTransactionId': bankTransactionId,
      },
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Fetch all diagnostics (for name-matching against a prescription)
  Future<List<Map<String, dynamic>>> fetchAllDiagnosticsForMatching() async {
    try {
      final response = await _apiService.get(
        Environment.DIAGNOSTICS,
        queryParameters: {'limit': 500, 'page': 1},
      );
      final data = response.data;
      final List<dynamic> items =
          data is Map ? (data['data'] ?? []) : (data as List);
      return items.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // Get All Bookings
  Future<Map<String, dynamic>> getBookings({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      Environment.BOOKINGS,
      queryParameters: {'page': page, 'limit': limit},
    );

    return response.data as Map<String, dynamic>;
  }

  // Get Upcoming Bookings (pending + confirmed, today or later)
  Future<List<BookingModel>> getUpcomingBookings() async {
    final result = await getBookings(limit: 100);
    final List<dynamic> data = result['data'] as List;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return data
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .where((booking) =>
            (booking.isPending || booking.isConfirmed) &&
            booking.scheduleDate.compareTo(todayStr) >= 0)
        .toList();
  }

  // Get Booking History
  Future<Map<String, dynamic>> getBookingHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      Environment.BOOKINGS_HISTORY,
      queryParameters: {'page': page, 'limit': limit},
    );

    return response.data as Map<String, dynamic>;
  }

  // Cancel Booking
  Future<BookingModel> cancelBooking({
    required int bookingId,
    required String reason,
  }) async {
    final response = await _apiService.delete(
      '${Environment.BOOKINGS}/$bookingId',
      data: {'reason': reason},
    );

    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }
}
