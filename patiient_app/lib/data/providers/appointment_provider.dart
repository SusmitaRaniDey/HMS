import 'package:get/get.dart';

import '../../config/environment.dart';
import '../../services/api_service.dart';
import '../models/appointment_model.dart';
import '../models/available_slots_model.dart';
import '../models/doctor_schedule_model.dart';
import '../models/time_slot_model.dart';

class AppointmentProvider {
  final ApiService _apiService = Get.find<ApiService>();

  // Get all doctors
  Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _apiService.get(
      Environment.DOCTORS,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Get Doctor's Working Days
  Future<DoctorScheduleModel> getDoctorWorkingDays(int doctorId) async {
    final response = await _apiService.get(
      '/appointments/doctor/$doctorId/working-days',
    );
    return DoctorScheduleModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Get Available Slots for a specific date
  Future<AvailableSlotsModel> getAvailableSlots({
    required int doctorId,
    required String date,
    String type = 'offline',
  }) async {
    final response = await _apiService.get(
      '/appointments/doctor/$doctorId/available-slots',
      queryParameters: {'date': date, 'type': type},
    );
    return AvailableSlotsModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Book Appointment
  Future<AppointmentModel> bookAppointment({
    required int doctorId,
    required String date,
    String? type,
    String? startTime,
    String? timeSlot,
    String? isPaid,
    String? paymentMethod,
    String? paymentStatus,
    String? transactionId,
    String? bankTransactionId,
    double? paidAmount,
    String? appointmentFor,
    String? otherPatientName,
    int? otherPatientAge,
    String? otherPatientGender,
    String? otherPatientContact,
  }) async {
    final response = await _apiService.post(
      Environment.APPOINTMENTS,
      data: {
        'doctorId': doctorId,
        'date': date,
        if (type != null) 'type': type,
        if (startTime != null) 'startTime': startTime,
        if (timeSlot != null) 'timeSlot': timeSlot,
        if (isPaid != null) 'isPaid': isPaid,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (transactionId != null) 'transactionId': transactionId,
        if (bankTransactionId != null) 'bankTransactionId': bankTransactionId,
        if (paidAmount != null) 'paidAmount': paidAmount,
        if (appointmentFor != null) 'appointmentFor': appointmentFor,
        if (otherPatientName != null) 'otherPatientName': otherPatientName,
        if (otherPatientAge != null) 'otherPatientAge': otherPatientAge,
        if (otherPatientGender != null) 'otherPatientGender': otherPatientGender,
        if (otherPatientContact != null) 'otherPatientContact': otherPatientContact,
      },
    );
    return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Confirms an online payment for an appointment created above. The
  // booking always starts unpaid server-side regardless of what
  // bookAppointment() was told — this is the only call that can actually
  // mark it paid, and the backend independently re-verifies the
  // transaction with SSLCommerz rather than trusting this request.
  Future<AppointmentModel> confirmAppointmentPayment({
    required int appointmentId,
    required String transactionId,
    String? validationId,
    String? bankTransactionId,
  }) async {
    final response = await _apiService.post(
      '/patient/appointments/$appointmentId/confirm-payment',
      data: {
        'transactionId': transactionId,
        if (validationId != null) 'validationId': validationId,
        if (bankTransactionId != null) 'bankTransactionId': bankTransactionId,
      },
    );
    return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  // Get All Appointments
  Future<Map<String, dynamic>> getAppointments({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      Environment.APPOINTMENTS,
      queryParameters: {'page': page, 'limit': limit},
    );

    return response.data as Map<String, dynamic>;
  }

  // Check if appointment already exists for doctor on specific date.
  // Throws on failure instead of silently returning false — callers must
  // not treat an inability to check as "no existing appointment", since
  // that would silently disable the duplicate-booking guard.
  Future<bool> checkExistingAppointment({
    required int doctorId,
    required String date,
  }) async {
    final response = await _apiService.get(
      '/patient/appointments/check-existing',
      queryParameters: {'doctorId': doctorId, 'date': date},
    );
    final data = response.data as Map<String, dynamic>;
    return data['exists'] as bool? ?? false;
  }

  // Get Upcoming Appointments (pending + confirmed, today or later)
  Future<List<AppointmentModel>> getUpcomingAppointments() async {
    final result = await getAppointments(limit: 100);
    final List<dynamic> data = result['data'] as List;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return data
        .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
        .where(
          (apt) =>
              (apt.isPending || apt.isConfirmed) &&
              apt.date.compareTo(todayStr) >= 0,
        )
        .toList();
  }

  // Get Appointment History
  Future<Map<String, dynamic>> getAppointmentHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      Environment.APPOINTMENTS_HISTORY,
      queryParameters: {'page': page, 'limit': limit},
    );

    return response.data as Map<String, dynamic>;
  }

  // Cancel Appointment
  Future<AppointmentModel> cancelAppointment({
    required int appointmentId,
    required String reason,
  }) async {
    final response = await _apiService.delete(
      '${Environment.APPOINTMENTS}/$appointmentId',
      data: {'reason': reason},
    );

    return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> getMeetingJoinUrl(int appointmentId) async {
    final response = await _apiService.get(
      Environment.appointmentMeetingJoin(appointmentId),
    );
    final data = response.data as Map<String, dynamic>;
    return data['meetingUrl'] as String;
  }

  // Get time slots (5-minute intervals) for a specific date
  Future<List<TimeSlotModel>> getTimeSlots({
    required int doctorId,
    required String date,
    String type = 'offline',
  }) async {
    try {
      final response = await _apiService.get(
        '/appointments/doctor/$doctorId/time-slots',
        queryParameters: {'date': date, 'type': type},
      );
      final List<dynamic> data = response.data as List;
      return data
          .map((json) => TimeSlotModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch time slots: $e');
    }
  }

  // Get booked appointments for a specific date.
  // Throws on failure instead of returning an empty list — the caller must
  // not treat "couldn't check" the same as "nothing is booked", since that
  // would silently disable the double-booking guard.
  Future<List<String>> getBookedTimes({
    required int doctorId,
    required String date,
    String type = 'offline',
  }) async {
    final response = await _apiService.get(
      '/appointments/doctor/$doctorId/booked-times',
      queryParameters: {'date': date, 'type': type},
    );
    final List<dynamic> data = response.data as List? ?? [];
    return data.map((e) => e.toString()).toList();
  }
}
