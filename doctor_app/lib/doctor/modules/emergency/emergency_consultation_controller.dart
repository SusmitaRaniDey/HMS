import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';

class EmergencyConsultationController extends GetxController {
  final ApiService _api = Get.find<ApiService>(tag: 'doctor');
  final isLoading = false.obs;
  final isEnabled = false.obs;
  final enabledByAdmin = true.obs;
  final from = TimeOfDay.now().obs;
  final until = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  DateTime? _parse(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  Future<void> load() async {
    isLoading.value = true;
    try {
      final data = (await _api.get('/doctor/emergency-availability')).data;
      isEnabled.value = data['isEnabled'] == true;
      enabledByAdmin.value = data['enabledByAdmin'] != false;
      final start = _parse(data['availableFrom']);
      final end = _parse(data['availableUntil']);
      if (start != null) from.value = TimeOfDay.fromDateTime(start);
      if (end != null) until.value = TimeOfDay.fromDateTime(end);
    } catch (e) {
      Get.snackbar('Unable to load', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  DateTime _todayAt(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> save(bool enabled) async {
    isLoading.value = true;
    try {
      if (!enabled) {
        await _api.post('/doctor/emergency-availability/off');
        isEnabled.value = false;
      } else {
        var start = _todayAt(from.value);
        var end = _todayAt(until.value);
        if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
        await _api.patch(
          '/doctor/emergency-availability',
          data: {
            'availableFrom': start.toUtc().toIso8601String(),
            'availableUntil': end.toUtc().toIso8601String(),
            'isEnabled': true,
          },
        );
        isEnabled.value = true;
      }
      Get.snackbar(
        'Emergency Consultation',
        enabled ? 'You are now available' : 'Emergency Mode is off',
      );
    } catch (e) {
      Get.snackbar('Update failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
