import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/appointment_model.dart';
import '../../data/models/available_slots_model.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../data/providers/appointment_provider.dart';
import '../../services/payment_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';

enum PaymentMethod { payNow, payInHospital }

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppointmentProvider _provider = AppointmentProvider();
  final PaymentService _paymentService = PaymentService();
  final StorageService _storageService = Get.find<StorageService>();
  final isLoading = ValueNotifier<bool>(false);
  final isLoadingSchedule = ValueNotifier<bool>(false);
  final isLoadingSlots = ValueNotifier<bool>(false);
  final isLoadingTimeSlots = ValueNotifier<bool>(false);

  late final dynamic _doctor;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedTimeSlot;
  DoctorScheduleModel? doctorSchedule;
  AvailableSlotsModel? availableSlots;
  List<TimeSlotModel> timeSlots = [];
  String? scheduleError;
  String? slotsError;
  bool isOnlineAppointment = false;

  String get _selectedAppointmentType =>
      isOnlineAppointment ? 'online' : 'offline';

  // New fields for appointment type and other patient info
  String appointmentFor = 'me'; // 'me' or 'other'
  final TextEditingController otherPatientNameController =
      TextEditingController();
  final TextEditingController otherPatientAgeController =
      TextEditingController();
  String? otherPatientGender;
  final TextEditingController otherPatientContactController =
      TextEditingController();
  final _genderOptions = ['Male', 'Female', 'Other'];

  bool get _canBook {
    if (selectedDate == null) return false;
    if (!(availableSlots?.hasAvailableSlots ?? false)) return false;
    if (selectedTimeSlot == null) return false;

    if (appointmentFor == 'other') {
      if (otherPatientNameController.text.trim().isEmpty) return false;
      if (otherPatientAgeController.text.trim().isEmpty) return false;
      if (otherPatientGender == null || otherPatientGender!.isEmpty)
        return false;
      if (otherPatientContactController.text.trim().isEmpty) return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _doctor = Get.arguments;
    _loadDoctorSchedule();
  }

  @override
  void dispose() {
    otherPatientNameController.dispose();
    otherPatientAgeController.dispose();
    otherPatientContactController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorSchedule() async {
    try {
      isLoadingSchedule.value = true;
      scheduleError = null;
      final schedule = await _provider.getDoctorWorkingDays(_doctor.id);
      doctorSchedule = schedule;
      setState(() {});
    } catch (e) {
      scheduleError = e.toString();
      Helpers.showErrorSnackbar(
        'Error',
        'Failed to load doctor schedule: ${e.toString()}',
      );
    } finally {
      isLoadingSchedule.value = false;
    }
  }

  Future<void> _checkAvailableSlots(DateTime date) async {
    try {
      isLoadingSlots.value = true;
      slotsError = null;
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final slots = await _provider.getAvailableSlots(
        doctorId: _doctor.id,
        date: dateString,
        type: isOnlineAppointment ? 'online' : 'offline',
      );
      availableSlots = slots;
      selectedTimeSlot = null;
      timeSlots = [];
      setState(() {});

      if (!slots.hasAvailableSlots) {
        Helpers.showErrorSnackbar(
          'No Slots',
          'No available slots for this date. Please select another date.',
        );
      }
    } catch (e) {
      slotsError = e.toString();
      availableSlots = null;
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoadingSlots.value = false;
    }
  }

  bool _isWorkingDay(DateTime date) {
    if (doctorSchedule == null) return false;
    if (isOnlineAppointment) {
      final dayName = DateFormat('EEEE').format(date);
      return doctorSchedule!.onlineDayNames.contains(dayName);
    }
    final dayName = DateFormat('EEEE').format(date);
    return doctorSchedule!.workingDayNames.contains(dayName);
  }

  Map<String, dynamic>? _onlineSlotForDate(DateTime date) {
    if (doctorSchedule == null) return null;
    final dayName = DateFormat('EEEE').format(date);
    for (final slot in doctorSchedule!.onlineSchedule) {
      final data = slot as Map<String, dynamic>;
      if ((data['day'] ?? data['date']) == dayName) return data;
    }
    return null;
  }

  bool _isSelectedTimeInOnlineSlot() {
    if (!isOnlineAppointment || selectedDate == null || selectedTime == null) {
      return true;
    }
    final slot = _onlineSlotForDate(selectedDate!);
    if (slot == null) return false;
    final startParts = (slot['startTime'] as String).split(':');
    final endParts = (slot['endTime'] as String).split(':');
    if (startParts.length < 2 || endParts.length < 2) return true;
    final selectedMinutes = selectedTime!.hour * 60 + selectedTime!.minute;
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return selectedMinutes >= startMinutes && selectedMinutes <= endMinutes;
  }

  // Returns the first available working day, or null if none found in 30 days.
  // Must only be called when doctorSchedule is non-null.
  DateTime? _getFirstWorkingDay() {
    DateTime current = DateTime.now();
    for (int i = 0; i < 30; i++) {
      if (_isWorkingDay(current)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }
    return null;
  }

  // Does NOT swallow errors: if the check fails we must not silently treat
  // it as "no existing appointment" (that would defeat the duplicate-
  // booking guard). Callers should let this propagate and block booking.
  Future<bool> _hasExistingAppointment(int doctorId, String date) async {
    return await _provider.checkExistingAppointment(
      doctorId: doctorId,
      date: date,
    );
  }

  // Returns working day entry for offline on [date], if the backend provides it
  Map<String, dynamic>? _offlineSlotForDate(DateTime date) {
    if (doctorSchedule == null) return null;
    final dayName = DateFormat('EEEE').format(date);
    for (final slot in doctorSchedule!.workingDays) {
      final data = slot as Map<String, dynamic>;
      if ((data['day'] ?? data['date']) == dayName) return data;
    }
    return null;
  }

  String _minutesToTimeStr(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // Fetch time slots for the selected date.
  // Tries the backend endpoint first; if it fails (404 / not implemented yet)
  // it generates 5-minute slots client-side from the schedule data already loaded.
  Future<void> _fetchTimeSlots() async {
    if (selectedDate == null) return;

    isLoadingTimeSlots.value = true;
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final type = isOnlineAppointment ? 'online' : 'offline';

      // ── 1. Try backend endpoint ────────────────────────────────────────
      List<TimeSlotModel>? backendSlots;
      try {
        backendSlots = await _provider.getTimeSlots(
          doctorId: _doctor.id,
          date: dateString,
          type: type,
        );
      } catch (_) {
        // Endpoint not available — fall through to client-side generation
      }

      if (backendSlots != null && backendSlots.isNotEmpty) {
        setState(() {
          timeSlots = backendSlots!;
          selectedTimeSlot = null;
        });
        _showTimeSlotSelection();
        return;
      }

      // ── 2. Generate slots client-side ─────────────────────────────────
      String? startStr;
      String? endStr;

      if (isOnlineAppointment) {
        final slot = _onlineSlotForDate(selectedDate!);
        startStr = slot?['startTime'] as String?;
        endStr = slot?['endTime'] as String?;
      } else {
        final slot = _offlineSlotForDate(selectedDate!);
        startStr = slot?['startTime'] as String?;
        endStr = slot?['endTime'] as String?;

        // Fallback: parse workingHours "HH:MM-HH:MM" from availableSlots
        if ((startStr == null || endStr == null) && availableSlots != null) {
          final wh = availableSlots!.workingHours;
          final sep = wh.contains(' - ') ? ' - ' : '-';
          final parts = wh.split(sep);
          if (parts.length >= 2) {
            startStr = parts[0].trim();
            endStr = parts[1].trim();
          }
        }
      }

      if (startStr == null || endStr == null) {
        Helpers.showErrorSnackbar(
          'Error',
          'Could not determine working hours for this day.',
        );
        return;
      }

      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      if (startParts.length < 2 || endParts.length < 2) {
        Helpers.showErrorSnackbar('Error', 'Invalid time format in schedule.');
        return;
      }

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      // Collect booked times. The backend is the source of truth; a local
      // on-device cache is only used to *supplement* it (e.g. a booking
      // just made on this device that hasn't propagated yet), never to
      // replace it. If the backend call fails we cannot trust the local
      // cache alone to reflect real availability (it's empty on fresh
      // installs / other devices), so we refuse to show slots as bookable
      // rather than risk a double-booking.
      final bookedSet = <String>{};

      try {
        final backendTimes = await _provider.getBookedTimes(
          doctorId: _doctor.id,
          date: dateString,
          type: type,
        );
        bookedSet.addAll(backendTimes);
      } catch (e) {
        Helpers.showErrorSnackbar(
          'Error',
          'Could not verify real-time slot availability. Please check your '
              'connection and try again before booking.',
        );
        setState(() {
          timeSlots = [];
          selectedTimeSlot = null;
        });
        return;
      }

      final slotKey = 'booked_slots_${_doctor.id}_${dateString}_$type';
      final localTimes = (_storageService.read<List>(slotKey) ?? []).map(
        (e) => e.toString(),
      );
      bookedSet.addAll(localTimes);

      final generated = <TimeSlotModel>[];
      int cur = startMinutes;
      int idx = 0;

      while (cur + 5 <= endMinutes) {
        final slotStart = _minutesToTimeStr(cur);
        final slotEnd = _minutesToTimeStr(cur + 5);
        final isBooked = bookedSet.contains(slotStart);

        generated.add(
          TimeSlotModel(
            slotId: idx,
            date: dateString,
            startTime: slotStart,
            endTime: slotEnd,
            isBooked: isBooked,
          ),
        );

        cur += 5;
        idx++;
      }

      setState(() {
        timeSlots = generated;
        selectedTimeSlot = null;
      });

      if (generated.isEmpty) {
        Helpers.showErrorSnackbar(
          'No Slots',
          'No time slots available for the selected date.',
        );
      } else {
        _showTimeSlotSelection();
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Error', 'Failed to load slots: $e');
    } finally {
      isLoadingTimeSlots.value = false;
    }
  }

  // Show time slot selection bottom sheet
  void _showTimeSlotSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            Text(
              'Select Booking Slot',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8.h),

            Text(
              'Choose a ${isOnlineAppointment ? 'meeting' : 'consultation'} time (5-minute slots)',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            SizedBox(height: 16.h),

            // Slot Grid
            Flexible(
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6.w,
                    mainAxisSpacing: 6.h,
                    childAspectRatio: 1.55,
                  ),
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final slot = timeSlots[index];
                    final isSelected = selectedTimeSlot == slot.startTime;

                    final borderColor = slot.isBooked
                        ? const Color(0xFFEF4444)
                        : isSelected
                        ? AppColors.primary
                        : const Color(0xFF22C55E);

                    return GestureDetector(
                      onTap: slot.isBooked
                          ? null
                          : () {
                              setState(() {
                                selectedTimeSlot = slot.startTime;
                                selectedTime = TimeOfDay(
                                  hour: int.parse(slot.startTime.split(':')[0]),
                                  minute: int.parse(
                                    slot.startTime.split(':')[1],
                                  ),
                                );
                              });
                              Get.back();
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: borderColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: borderColor, width: 1.2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              slot.isBooked
                                  ? Icons.lock
                                  : isSelected
                                  ? Icons.check_circle
                                  : Icons.access_time,
                              color: borderColor,
                              size: 13.sp,
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              slot.startTime,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: borderColor,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              slot.endTime,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w500,
                                color: borderColor.withValues(alpha: 0.8),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text('Available', style: AppTextStyles.body3),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text('Booked', style: AppTextStyles.body3),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentOptions() {
    final doctor = _doctor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              Text(
                'Select Payment Method',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8.h),

              Text(
                'Choose how you want to pay the consultation fee',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 24.h),

              // Pay Now Option
              InkWell(
                onTap: () {
                  Get.back();
                  _processBooking(PaymentMethod.payNow);
                },
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay Now',
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Pay securely via Bkash, Nagad, Card & more',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),

              // Pay at Hospital Option - Only for offline appointments
              if (!isOnlineAppointment) ...[
                SizedBox(height: 12.h),
                InkWell(
                  onTap: () {
                    Get.back();
                    _processBooking(PaymentMethod.payInHospital);
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.local_hospital,
                            color: AppColors.warning,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pay at Hospital',
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Pay when you arrive at the hospital',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textSecondary,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Consultation Fee Display
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consultation Fee',
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      doctor.feeTextForType(_selectedAppointmentType),
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processBooking(PaymentMethod paymentMethod) async {
    if (selectedDate == null) {
      Helpers.showErrorSnackbar('Error', 'Please select a date');
      return;
    }

    if (availableSlots == null || !availableSlots!.hasAvailableSlots) {
      Helpers.showErrorSnackbar(
        'Error',
        'No available slots for selected date',
      );
      return;
    }

    if (!_isSelectedTimeInOnlineSlot()) {
      final slot = _onlineSlotForDate(selectedDate!);
      Helpers.showErrorSnackbar(
        'Error',
        'Please select a meeting time between ${slot?['startTime']} and ${slot?['endTime']}',
      );
      return;
    }

    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final doctor = _doctor;
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate!);

      final hasExisting = await _hasExistingAppointment(doctor.id, dateString);
      if (hasExisting) {
        Helpers.showErrorSnackbar(
          'Error',
          'You already have an appointment with this doctor on this date',
        );
        isLoading.value = false;
        return;
      }

      String? transactionId;
      String? bankTransactionId;
      String? validationId;
      String appointmentIsPaid = 'unpaid';
      String appointmentPaymentStatus = 'pending';
      final String appointmentPaymentMethod =
          paymentMethod == PaymentMethod.payNow ? 'pay_now' : 'pay_in_hospital';

      bool paymentSucceeded = false;

      if (paymentMethod == PaymentMethod.payNow) {
        final patient = _storageService.getPatient();
        transactionId = _paymentService.generateTransactionId(prefix: 'APT');

        final SSLCTransactionInfoModel? paymentResult = await _paymentService
            .initiatePayment(
              amount: doctor.feeForType(_selectedAppointmentType),
              transactionId: transactionId,
              productName: 'Consultation with ${doctor.name}',
              customerName: patient?['name'] ?? 'Patient',
              customerEmail: patient?['email'] ?? 'patient@example.com',
              customerPhone: patient?['phone'] ?? '01700000000',
            );

        if (!_paymentService.isPaymentSuccessful(paymentResult)) {
          isLoading.value = false;
          if (!mounted) return;
          _paymentService.showPaymentStatusDialog(
            context: context,
            isSuccess: false,
            message: 'Payment was not completed. Please try again.',
          );
          return;
        }

        bankTransactionId = _paymentService.getBankTransactionId(paymentResult);
        validationId = _paymentService.getValidationId(paymentResult);
        appointmentIsPaid = 'paid';
        appointmentPaymentStatus = 'completed';
        paymentSucceeded = true;
        // NOTE: the "payment successful" confirmation is intentionally
        // shown only *after* the booking record is confirmed created
        // below — not here — so the user is never told "success" before
        // we know the appointment actually exists.
      }

      // Build ISO start time for both online and offline (slot is selected for both)
      String? isoStartTime;
      if (selectedDate != null && selectedTime != null) {
        final dt = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );
        // Convert to UTC before serializing so the string carries an
        // explicit offset ('Z') instead of being ambiguous local time.
        isoStartTime = dt.toUtc().toIso8601String();
      }

      // Prepare other patient data if applicable
      String? otherPatientAge;
      if (appointmentFor == 'other') {
        otherPatientAge = otherPatientAgeController.text.trim();
      }

      final appointmentType = isOnlineAppointment ? 'online' : 'offline';

      // If payment already succeeded, the transaction cannot be undone —
      // so a failure to create the booking record must not just be
      // reported as a generic error that loses the transaction ID. Retry
      // a couple of times with a short backoff before giving up.
      final maxAttempts = paymentSucceeded ? 3 : 1;
      Object? bookingError;
      bool bookingCreated = false;
      AppointmentModel? createdAppointment;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          createdAppointment = await _provider.bookAppointment(
            doctorId: doctor.id,
            date: dateString,
            type: appointmentType,
            startTime: isoStartTime,
            timeSlot: selectedTimeSlot,
            isPaid: appointmentIsPaid,
            paymentMethod: appointmentPaymentMethod,
            paymentStatus: appointmentPaymentStatus,
            transactionId: transactionId,
            bankTransactionId: bankTransactionId,
            paidAmount: paymentMethod == PaymentMethod.payNow
                ? doctor.feeForType(appointmentType)
                : null,
            appointmentFor: appointmentFor,
            otherPatientName: appointmentFor == 'other'
                ? otherPatientNameController.text.trim()
                : null,
            otherPatientAge: appointmentFor == 'other'
                ? int.tryParse(otherPatientAge ?? '')
                : null,
            otherPatientGender: appointmentFor == 'other'
                ? otherPatientGender
                : null,
            otherPatientContact: appointmentFor == 'other'
                ? otherPatientContactController.text.trim()
                : null,
          );
          bookingCreated = true;
          bookingError = null;
          break;
        } catch (e) {
          bookingError = e;
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(seconds: attempt));
          }
        }
      }

      if (!bookingCreated) {
        if (paymentSucceeded) {
          if (!mounted) return;
          await _showPaymentSucceededBookingFailedDialog(
            transactionId: transactionId,
            error: bookingError,
          );
        } else {
          Helpers.showErrorSnackbar(
            'Error',
            bookingError?.toString() ?? 'Failed to create appointment.',
          );
        }
        return;
      }

      if (paymentSucceeded) {
        // The booking always starts unpaid server-side — this is the call
        // that actually marks it paid, after the backend independently
        // re-verifies the transaction with SSLCommerz. Best-effort: if this
        // fails, the appointment still exists (just shows unpaid) rather
        // than losing the booking entirely, and can be reconciled later.
        if (createdAppointment != null && transactionId != null) {
          try {
            await _provider.confirmAppointmentPayment(
              appointmentId: createdAppointment.id,
              transactionId: transactionId,
              validationId: validationId,
              bankTransactionId: bankTransactionId,
            );
          } catch (e) {
            debugPrint('Payment confirmation failed: $e');
          }
        }

        if (!mounted) return;
        _paymentService.showPaymentStatusDialog(
          context: context,
          isSuccess: true,
          message: 'Payment successful! Your appointment is being confirmed.',
        );
      } else if (paymentMethod == PaymentMethod.payInHospital) {
        await Get.dialog(
          AlertDialog(
            title: const Text('Appointment Confirmed'),
            content: const Text('Okay, please Pay your Fees at hospital.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.offAllNamed('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } else {
        Helpers.showSuccessSnackbar(
          'Success',
          'Appointment booked successfully!',
        );
        Get.back();
      }
    } catch (e) {
      Helpers.showErrorSnackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Shown when payment succeeded but the booking record could not be
  // created even after retries. The transaction ID must not be lost here —
  // it's the reference the support desk needs to reconcile the payment.
  Future<void> _showPaymentSucceededBookingFailedDialog({
    required String? transactionId,
    Object? error,
  }) {
    return Get.dialog(
      AlertDialog(
        title: const Text('Booking Not Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your payment was successful, but we could not confirm your '
              'appointment booking due to a connection issue. Please '
              'contact hospital support with the transaction ID below so '
              'they can confirm your appointment or process a refund.',
            ),
            if (transactionId != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        'Transaction ID: $transactionId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy transaction ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: transactionId));
                        Helpers.showInfoSnackbar(
                          'Copied',
                          'Transaction ID copied to clipboard',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.offAllNamed('/home');
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _doctor;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: ValueListenableBuilder(
        valueListenable: isLoadingSchedule,
        builder: (context, loading, _) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (scheduleError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Failed to load schedule',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      scheduleError ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(text: 'Retry', onPressed: _loadDoctorSchedule),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Info Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 32.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(doctor.specialty, style: AppTextStyles.body2),
                            SizedBox(height: 4.h),
                            Text(
                              'Fee: ${doctor.feeTextForType(_selectedAppointmentType)}',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Appointment Type Selection ──────────────────────────────
                Text(
                  'Appointment For',
                  style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 12.h),

                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => appointmentFor = 'me'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: appointmentFor == 'me'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: appointmentFor == 'me'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18.sp,
                                  color: appointmentFor == 'me'
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'For Me',
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: appointmentFor == 'me'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: appointmentFor == 'me'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => appointmentFor = 'other'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: appointmentFor == 'other'
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 18.sp,
                                  color: appointmentFor == 'other'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'For Another',
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: appointmentFor == 'other'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: appointmentFor == 'other'
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Other Patient Form (shown only when "For Another" is selected) ──
                if (appointmentFor == 'other') ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Information',
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Patient Name
                        TextField(
                          controller: otherPatientNameController,
                          decoration: InputDecoration(
                            labelText: 'Patient Name',
                            hintText: 'Enter patient name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: 12.h),
                        // Patient Age
                        TextField(
                          controller: otherPatientAgeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            hintText: 'Enter age',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: 12.h),
                        // Patient Gender
                        DropdownButtonFormField<String>(
                          value: otherPatientGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            hintText: 'Select gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            prefixIcon: const Icon(Icons.wc),
                          ),
                          items: _genderOptions.map((gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => otherPatientGender = value);
                          },
                        ),
                        SizedBox(height: 12.h),
                        // Patient Contact
                        TextField(
                          controller: otherPatientContactController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            hintText: 'Enter contact number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            isOnlineAppointment = false;
                            selectedDate = null;
                            selectedTime = null;
                            selectedTimeSlot = null;
                            timeSlots = [];
                            availableSlots = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: !isOnlineAppointment
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: !isOnlineAppointment
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_hospital_outlined,
                                  size: 18.sp,
                                  color: !isOnlineAppointment
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'In-Person',
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: !isOnlineAppointment
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !isOnlineAppointment
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            isOnlineAppointment = true;
                            selectedDate = null;
                            selectedTime = null;
                            selectedTimeSlot = null;
                            timeSlots = [];
                            availableSlots = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isOnlineAppointment
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_outlined,
                                  size: 18.sp,
                                  color: isOnlineAppointment
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Online (Zoom)',
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: isOnlineAppointment
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isOnlineAppointment
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Working Days Info
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: AppColors.success,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            isOnlineAppointment
                                ? 'Online Dates'
                                : 'Working Days',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      if (doctorSchedule == null ||
                          (!isOnlineAppointment &&
                              doctorSchedule!.workingDayNames.isEmpty) ||
                          (isOnlineAppointment &&
                              doctorSchedule!.onlineDayNames.isEmpty))
                        Text(
                          isOnlineAppointment
                              ? 'No online days available for this doctor.'
                              : 'No working days available for this doctor.',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children:
                              (isOnlineAppointment
                                      ? doctorSchedule!.onlineDayNames
                                      : doctorSchedule!.workingDayNames)
                                  .map((day) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Text(
                                        day,
                                        style: AppTextStyles.body2.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Select Date
                Text(
                  'Select Date',
                  style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 12.h),

                InkWell(
                  onTap: doctorSchedule == null
                      ? null
                      : () async {
                          final firstWorkingDay = _getFirstWorkingDay();
                          if (firstWorkingDay == null) {
                            Helpers.showErrorSnackbar(
                              'No Dates',
                              'No available appointment dates for this doctor in the next 30 days.',
                            );
                            return;
                          }
                          final date = await showDatePicker(
                            context: context,
                            initialDate: firstWorkingDay,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            selectableDayPredicate: _isWorkingDay,
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                              selectedTime = null;
                            });
                            await _checkAvailableSlots(date);
                          }
                        },
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: doctorSchedule == null
                          ? AppColors.background
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selectedDate != null
                            ? AppColors.primary
                            : AppColors.border,
                        width: selectedDate != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: selectedDate != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedDate != null
                                    ? DateFormat(
                                        'EEEE, MMMM d, yyyy',
                                      ).format(selectedDate!)
                                    : doctorSchedule == null
                                    ? 'Loading schedule...'
                                    : 'Choose a date',
                                style: AppTextStyles.body1.copyWith(
                                  color: selectedDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                ),

                // Available Slots Info
                if (selectedDate != null)
                  ValueListenableBuilder(
                    valueListenable: isLoadingSlots,
                    builder: (context, loading, _) {
                      if (loading) {
                        return Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (availableSlots != null) {
                        return Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: availableSlots!.hasAvailableSlots
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: availableSlots!.hasAvailableSlots
                                    ? AppColors.success.withOpacity(0.3)
                                    : AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  availableSlots!.hasAvailableSlots
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: availableSlots!.hasAvailableSlots
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        availableSlots!.hasAvailableSlots
                                            ? 'Available Slots: ${availableSlots!.availableSlots}/${availableSlots!.consultLimitPerDay}'
                                            : 'No Available Slots',
                                        style: AppTextStyles.body2.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              availableSlots!.hasAvailableSlots
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        '${availableSlots!.bookedPercentage} booked',
                                        style: AppTextStyles.body3.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),

                // Booking Slot — shown for both in-person and online once a date with available slots is chosen
                if (selectedDate != null &&
                    (availableSlots?.hasAvailableSlots ?? false)) ...[
                  SizedBox(height: 20.h),
                  Text(
                    'Booking Slot',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Selected slot display
                  if (selectedTimeSlot != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      margin: EdgeInsets.only(bottom: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Selected slot: $selectedTimeSlot',
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Select / change slot button
                  ValueListenableBuilder(
                    valueListenable: isLoadingTimeSlots,
                    builder: (context, loading, _) => InkWell(
                      onTap: loading ? null : _fetchTimeSlots,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: selectedTimeSlot != null
                                ? AppColors.primary
                                : AppColors.border,
                            width: selectedTimeSlot != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: selectedTimeSlot != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: loading
                                  ? SizedBox(
                                      height: 20.h,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      selectedTimeSlot != null
                                          ? 'Change slot'
                                          : 'Select a booking slot',
                                      style: AppTextStyles.body1.copyWith(
                                        color: selectedTimeSlot != null
                                            ? AppColors.textPrimary
                                            : AppColors.textHint,
                                      ),
                                    ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16.sp,
                              color: AppColors.textHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Zoom info note for online appointments
                if (isOnlineAppointment) ...[
                  if (selectedDate != null &&
                      _onlineSlotForDate(selectedDate!) != null) ...[
                    SizedBox(height: 10.h),
                    Text(
                      'Available time: ${_onlineSlotForDate(selectedDate!)!['startTime']} - ${_onlineSlotForDate(selectedDate!)!['endTime']}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.videocam,
                          color: AppColors.info,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'A Zoom meeting link will be generated automatically after booking.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 48.h),

                // Confirm Button — opens payment options
                ValueListenableBuilder(
                  valueListenable: isLoading,
                  builder: (context, loading, _) => CustomButton(
                    text: 'Confirm Booking',
                    onPressed: _canBook ? _showPaymentOptions : null,
                    isLoading: loading,
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
