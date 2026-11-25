import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'emergency_doctors_controller.dart';

class EmergencyDoctorsScreen extends GetView<EmergencyDoctorsController> {
  const EmergencyDoctorsScreen({super.key});

  String _until(dynamic value) {
    final date = DateTime.tryParse(value.toString())?.toLocal();
    return date == null ? 'Unavailable' : DateFormat.jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Doctors')),
      body: Obx(() {
        if (controller.isLoading.value && controller.doctors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.doctors.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshDoctors,
            child: ListView(
              children: const [
                SizedBox(height: 180),
                Icon(Icons.medical_services_outlined, size: 64),
                SizedBox(height: 16),
                Center(child: Text('No emergency doctors available right now')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshDoctors,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.doctors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final doctor = controller.doctors[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor['name'] ?? 'Doctor',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(doctor['department'] ?? ''),
                              ],
                            ),
                          ),
                          const Chip(
                            avatar: Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 12,
                            ),
                            label: Text('Online'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('${doctor['experience'] ?? 0} Years Experience'),
                      Text('Fee: ৳${doctor['emergencyFee'] ?? 0}'),
                      Text(
                        'Available Until: ${_until(doctor['availableUntil'])}',
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => controller.consultNow(doctor),
                          icon: const Icon(Icons.video_call),
                          label: const Text('Consult Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
