import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class Helpers {
  // ========== SNACKBARS ==========

  static void showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  static void showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  static void showWarningSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.warning,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  static void showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.info,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ========== DIALOGS ==========

  static void showLoadingDialog({String message = 'Loading...'}) {
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
    Color? confirmColor,
  }) async {
    bool result = false;

    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              result = false;
              Get.back();
            },
            child: Text(
              cancelText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              result = true;
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result;
  }

  // ========== DATE FORMATTING ==========

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  static String formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  static String formatTime(String timeString) {
    // Assuming timeString is in format "HH:mm"
    try {
      final time = DateFormat('HH:mm').parse(timeString);
      return DateFormat('hh:mm a').format(time);
    } catch (e) {
      return timeString;
    }
  }

  static String getRelativeDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final compareDate = DateTime(date.year, date.month, date.day);

      final difference = compareDate.difference(today).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Tomorrow';
      } else if (difference == -1) {
        return 'Yesterday';
      } else if (difference > 1 && difference <= 7) {
        return 'In $difference days';
      } else if (difference < -1 && difference >= -7) {
        return '${difference.abs()} days ago';
      } else {
        return formatDate(dateString);
      }
    } catch (e) {
      return dateString;
    }
  }

  // ========== STATUS HELPERS ==========

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.pending;
      case 'confirmed':
        return AppColors.confirmed;
      case 'completed':
        return AppColors.completed;
      case 'cancelled':
        return AppColors.cancelled;
      case 'rejected':
        return AppColors.rejected;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  // ========== CURRENCY FORMATTING ==========

  static String formatCurrency(double amount) {
    return '৳${amount.toStringAsFixed(0)}';
  }

  // ========== PHONE FORMATTING ==========

  static String formatPhoneNumber(String phone) {
    // Simple formatting for display
    if (phone.startsWith('+880')) {
      return '+880 ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  // ========== VALIDATION ==========

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$');
    return phoneRegex.hasMatch(phone);
  }
}