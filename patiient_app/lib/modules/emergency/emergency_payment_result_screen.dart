import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
import '../../data/providers/appointment_provider.dart';
import '../../utils/helpers.dart';

class EmergencyPaymentSuccessScreen extends StatelessWidget {
  const EmergencyPaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = Map<String, dynamic>.from(Get.arguments as Map);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 84),
          const SizedBox(height: 12),
          Text(
            'Payment Successful',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your emergency consultation is ready.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _EmergencyDetailsCard(booking: booking),
          const SizedBox(height: 20),
          if ((booking['zoomJoinUrl']?.toString() ?? '').isNotEmpty)
            FilledButton.icon(
              onPressed: () async {
                final appointmentId = booking['id'] as int;
                try {
                  final url = await AppointmentProvider().getMeetingJoinUrl(
                    appointmentId,
                  );
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  Helpers.showErrorSnackbar('Meeting unavailable', e.toString());
                }
              },
              icon: const Icon(Icons.video_call),
              label: const Text('Join Consultation'),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.APPOINTMENTS),
            child: const Text('View My Appointments'),
          ),
        ],
      ),
    );
  }
}

class EmergencyPaymentFailedScreen extends StatelessWidget {
  const EmergencyPaymentFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Map<String, dynamic>.from(Get.arguments as Map);
    final cancelled = args['cancelled'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(cancelled ? 'Payment Cancelled' : 'Payment Failed'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              cancelled ? Icons.cancel_outlined : Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 84,
            ),
            const SizedBox(height: 18),
            Text(
              cancelled ? 'Payment was cancelled' : 'Payment was not completed',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'No payment was recorded. You can safely retry using SSLCommerz.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.offNamed(
                  AppRoutes.EMERGENCY_PAYMENT,
                  arguments: args['doctor'],
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Payment'),
              ),
            ),
            TextButton(
              onPressed: Get.back,
              child: const Text('Choose another doctor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyDetailsCard extends StatelessWidget {
  const _EmergencyDetailsCard({required this.booking});
  final Map<String, dynamic> booking;

  Widget row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final doctor = booking['doctor'] is Map
        ? Map<String, dynamic>.from(booking['doctor'])
        : <String, dynamic>{};
    final start = DateTime.tryParse(booking['startTime']?.toString() ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            row('Doctor', doctor['name']?.toString() ?? 'Doctor'),
            row(
              'Date & time',
              start == null
                  ? 'Now'
                  : DateFormat('d MMM y, h:mm a').format(start.toLocal()),
            ),
            row(
              'Emergency fee',
              '৳${booking['totalAmount'] ?? booking['paidAmount'] ?? 0}',
            ),
            row('Transaction ID', booking['transactionId']?.toString() ?? '—'),
            row(
              'Booking status',
              booking['bookingStatus']?.toString() ?? 'confirmed',
            ),
          ],
        ),
      ),
    );
  }
}
