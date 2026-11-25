import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import 'emergency_consultation_controller.dart';

class EmergencyConsultationScreen
    extends GetView<EmergencyConsultationController> {
  const EmergencyConsultationScreen({super.key});

  Future<void> _pick(BuildContext context, bool start) async {
    final chosen = await showTimePicker(
      context: context,
      initialTime: start ? controller.from.value : controller.until.value,
    );
    if (chosen != null) {
      if (start) {
        controller.from.value = chosen;
      } else {
        controller.until.value = chosen;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Consultation')),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Emergency Mode'),
                            subtitle: Text(
                              controller.enabledByAdmin.value
                                  ? 'Appear to patients during this time'
                                  : 'Disabled by administrator',
                            ),
                            value: controller.isEnabled.value,
                            activeThumbColor: AppColors.primary,
                            onChanged: controller.enabledByAdmin.value
                                ? controller.save
                                : null,
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.schedule),
                            title: const Text('Available From'),
                            trailing: Text(
                              controller.from.value.format(context),
                            ),
                            onTap: () => _pick(context, true),
                          ),
                          ListTile(
                            leading: const Icon(Icons.timer_outlined),
                            title: const Text('Available Until'),
                            trailing: Text(
                              controller.until.value.format(context),
                            ),
                            onTap: () => _pick(context, false),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: controller.enabledByAdmin.value
                                  ? () => controller.save(true)
                                  : null,
                              icon: const Icon(Icons.emergency),
                              label: const Text('Save and Turn On'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
