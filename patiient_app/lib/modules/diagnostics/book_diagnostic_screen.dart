import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/booking_model.dart';
import '../../data/providers/booking_provider.dart';
import '../../services/payment_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

enum PaymentMethod { payNow, payInHospital }

class BookDiagnosticScreen extends StatefulWidget {
  const BookDiagnosticScreen({super.key});

  @override
  State<BookDiagnosticScreen> createState() => _BookDiagnosticScreenState();
}

class _BookDiagnosticScreenState extends State<BookDiagnosticScreen> {
  final BookingProvider _provider = BookingProvider();
  final PaymentService _paymentService = PaymentService();
  final StorageService _storageService = Get.find<StorageService>();

  final TextEditingController notesController = TextEditingController();
  final isLoading = ValueNotifier<bool>(false);

  DateTime? selectedDate;

  // Show payment options dialog
  void _showPaymentOptions() {
    final diagnostic = Get.arguments;

    showModalBottomSheet(
      context: context,
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
              'Select Payment Method',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8.h),

            Text(
              'Choose how you want to pay for this test',
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
                            'Pay securely using SSLCommerz',
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

            SizedBox(height: 12.h),

            // Pay at Hospital Option
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

            SizedBox(height: 24.h),

            // Price Display
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
                    'Total Amount',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    diagnostic.priceText,
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
    );
  }

  // Process booking based on payment method
  Future<void> _processBooking(PaymentMethod paymentMethod) async {
    final diagnostic = Get.arguments;

    isLoading.value = true;

    try {
      String? transactionId;
      String? bankTransactionId;
      String? validationId;
      String paymentStatus = 'pending';
      bool paymentSucceeded = false;

      // If Pay Now is selected, process payment first
      if (paymentMethod == PaymentMethod.payNow) {
        // Get patient info
        final patient = _storageService.getPatient();

        // Generate unique transaction ID
        transactionId = _paymentService.generateTransactionId();

        // Initiate SSLCommerz payment
        final SSLCTransactionInfoModel? paymentResult = await _paymentService
            .initiatePayment(
              amount: diagnostic.price,
              transactionId: transactionId,
              productName: diagnostic.testName,
              customerName: patient?['name'] ?? 'Patient',
              customerEmail: patient?['email'] ?? 'patient@example.com',
              customerPhone: patient?['phone'] ?? '01700000000',
            );

        // Check if payment was successful
        if (!_paymentService.isPaymentSuccessful(paymentResult)) {
          isLoading.value = false;
          _paymentService.showPaymentStatusDialog(
            context: context,
            isSuccess: false,
            message: 'Payment was not completed. Please try again.',
          );
          return;
        }

        // Get transaction details
        bankTransactionId = _paymentService.getBankTransactionId(paymentResult);
        validationId = _paymentService.getValidationId(paymentResult);
        paymentStatus = 'completed';
        paymentSucceeded = true;
        // NOTE: the "payment successful" confirmation is shown only after
        // the booking record is confirmed created below, not here — so the
        // user is never told "success" before we know the booking exists.
      }

      // Proceed with booking
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate!);

      // If payment already succeeded, the transaction cannot be undone —
      // so a failure to create the booking record must not just be
      // reported as a generic error that loses the transaction ID. Retry
      // a couple of times with a short backoff before giving up.
      final maxAttempts = paymentSucceeded ? 3 : 1;
      Object? bookingError;
      bool bookingCreated = false;
      BookingModel? createdBooking;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          createdBooking = await _provider.bookDiagnostic(
            diagnosticId: diagnostic.id,
            scheduleDate: dateString,
            notes: notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
            paymentMethod: paymentMethod == PaymentMethod.payNow
                ? 'pay_now'
                : 'pay_in_hospital',
            paymentStatus: paymentStatus,
            isPaid: paymentSucceeded ? 'paid' : 'unpaid',
            transactionId: transactionId,
            bankTransactionId: bankTransactionId,
            paidAmount: paymentMethod == PaymentMethod.payNow
                ? diagnostic.price
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
            bookingError?.toString() ?? 'Failed to create booking.',
          );
        }
        return;
      }

      // Show confirmation dialog for Pay at Hospital
      if (paymentSucceeded) {
        // The booking always starts unpaid/pending server-side — this is
        // the call that actually marks it paid and auto-confirms it, after
        // the backend independently re-verifies the transaction with
        // SSLCommerz. Best-effort: if this fails, the booking still exists
        // (just shows unpaid/pending) rather than being lost entirely.
        if (createdBooking != null && transactionId != null) {
          try {
            await _provider.confirmDiagnosticPayment(
              bookingId: createdBooking.id,
              transactionId: transactionId,
              validationId: validationId,
              bankTransactionId: bankTransactionId,
            );
          } catch (e) {
            debugPrint('Payment confirmation failed: $e');
          }
        }

        _paymentService.showPaymentStatusDialog(
          context: context,
          isSuccess: true,
          message: 'Payment successful! Your booking is being confirmed.',
        );
      } else if (paymentMethod == PaymentMethod.payInHospital) {
        await Get.dialog(
          AlertDialog(
            title: const Text('Booking Confirmed'),
            content: const Text('Okay, Please pay the payment at Hospital.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.offAllNamed('/home'); // Navigate to home dashboard
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
        // For Pay Now, just go back normally
        Helpers.showSuccessSnackbar(
          'Success',
          'Diagnostic test booked successfully!',
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
              'test booking due to a connection issue. Please contact '
              'hospital support with the transaction ID below so they can '
              'confirm your booking or process a refund.',
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
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diagnostic = Get.arguments;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Test')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Info Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
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
                      Icons.biotech,
                      size: 32.sp,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diagnostic.testName,
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(diagnostic.category, style: AppTextStyles.body2),
                        SizedBox(height: 4.h),
                        Text(
                          'Price: ${diagnostic.priceText}',
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

            SizedBox(height: 32.h),

            // Select Date
            Text(
              'Select Date',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 12.h),

            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      child: Text(
                        selectedDate != null
                            ? DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(selectedDate!)
                            : 'Choose a date',
                        style: AppTextStyles.body1.copyWith(
                          color: selectedDate != null
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

            SizedBox(height: 32.h),

            // Notes (Optional)
            CustomTextField(
              controller: notesController,
              label: 'Additional Notes (Optional)',
              hint: 'Any special instructions or notes...',
              maxLines: 4,
            ),

            SizedBox(height: 48.h),

            // Confirm Button - Shows payment options
            ValueListenableBuilder(
              valueListenable: isLoading,
              builder: (context, loading, _) => CustomButton(
                text: 'Confirm Booking',
                onPressed: () {
                  if (selectedDate == null) {
                    Helpers.showErrorSnackbar('Error', 'Please select a date');
                    return;
                  }
                  _showPaymentOptions();
                },
                isLoading: loading,
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
