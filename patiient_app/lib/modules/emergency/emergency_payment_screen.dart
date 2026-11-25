import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'emergency_payment_controller.dart';

class EmergencyPaymentScreen extends GetView<EmergencyPaymentController> {
  const EmergencyPaymentScreen({super.key});

  Widget _row(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, softWrap: true)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Consultation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.primaryContainer,
                      child: Icon(Icons.medical_services, color: color.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.doctor['name']?.toString() ?? 'Doctor',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.doctor['department']?.toString() ??
                                'General Medicine',
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.videocam_outlined, size: 18),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Emergency Online Consultation',
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 26),
                    _row(
                      'Emergency consultation fee',
                      '৳${controller.emergencyFee.toStringAsFixed(2)}',
                    ),
                    if (controller.additionalFee > 0)
                      _row(
                        'Additional emergency fee',
                        '৳${controller.additionalFee.toStringAsFixed(2)}',
                      ),
                    const Divider(),
                    _row(
                      'Total amount',
                      '৳${controller.total.toStringAsFixed(2)}',
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: controller.error.value == null
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.error.value!,
                          style: TextStyle(color: color.onErrorContainer),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.isPaying.value ? null : controller.payNow,
                icon: controller.isPaying.value
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    controller.isPaying.value
                        ? 'Opening secure payment…'
                        : 'Pay Now • ৳${controller.total.toStringAsFixed(2)}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
