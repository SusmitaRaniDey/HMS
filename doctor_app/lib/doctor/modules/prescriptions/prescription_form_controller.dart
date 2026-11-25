import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/appointment_model.dart';
import '../../data/providers/prescription_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';

class PrescriptionFormController extends GetxController {
  final DoctorPrescriptionProvider _provider = DoctorPrescriptionProvider();
  final StorageService _storage = Get.find<StorageService>(tag: 'doctor');

  final isSubmitting = false.obs;

  // Form fields
  final diagnosisCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final patientAgeCtrl = TextEditingController();

  // Medicines — each entry is {name, dose, frequency, duration}
  final medicines = <Map<String, TextEditingController>>[].obs;

  // Tests suggested
  final testControllers = <TextEditingController>[].obs;

  // Diagnostics fetched from the catalogue for autocomplete suggestions
  final availableDiagnostics = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    addMedicineRow();
    addTestRow();
    _fetchDiagnostics();
  }

  Future<void> _fetchDiagnostics() async {
    try {
      availableDiagnostics.value = await _provider.fetchDiagnosticNames();
    } catch (_) {}
  }

  Future<List<MedicineSuggestion>> searchMedicines(String query) =>
      _provider.searchMedicines(query);

  void addMedicineRow() {
    medicines.add({
      'name': TextEditingController(),
      'dose': TextEditingController(),
      'frequency': TextEditingController(),
      'duration': TextEditingController(),
    });
  }

  void removeMedicineRow(int index) {
    if (medicines.length <= 1) return;
    final row = medicines.removeAt(index);
    for (final ctrl in row.values) {
      ctrl.dispose();
    }
  }

  void addTestRow() {
    testControllers.add(TextEditingController());
  }

  void removeTestRow(int index) {
    if (testControllers.length <= 1) return;
    testControllers.removeAt(index).dispose();
  }

  Future<void> submit(AppointmentModel appointment) async {
    if (isSubmitting.value) return;

    final doctor = _storage.getDoctor();
    if (doctor == null) {
      Get.snackbar('Error', 'Doctor session expired');
      return;
    }

    final patientId = appointment.patientId ?? appointment.patient?.id;
    if (patientId == null || patientId == 0) {
      Get.snackbar(
        'Error',
        'Patient information is missing for this appointment',
      );
      return;
    }

    if (diagnosisCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a diagnosis before submitting');
      return;
    }

    final hasMedicine = medicines.any(
      (row) => row['name']!.text.trim().isNotEmpty,
    );
    if (!hasMedicine) {
      Get.snackbar(
        'Error',
        'Please add at least one medicine with a name',
      );
      return;
    }

    final medicinesList = medicines
        .map(
          (row) => {
            'name': row['name']!.text.trim(),
            'dose': row['dose']!.text.trim(),
            'frequency': row['frequency']!.text.trim(),
            'duration': row['duration']!.text.trim(),
          },
        )
        .toList();

    final testsList = testControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    isSubmitting.value = true;
    try {
      await _provider.createPrescription(
        appointmentId: appointment.id,
        doctorId: doctor['id'] as int,
        patientId: patientId,
        patientAge: patientAgeCtrl.text.trim().isEmpty
            ? null
            : patientAgeCtrl.text.trim(),
        diagnosis: diagnosisCtrl.text.trim().isEmpty
            ? null
            : diagnosisCtrl.text.trim(),
        medicines: medicinesList,
        testsSuggested: testsList,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );

      Get.back();
      Get.snackbar(
        'Success',
        'Prescription submitted and PDF generated',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    diagnosisCtrl.dispose();
    notesCtrl.dispose();
    patientAgeCtrl.dispose();
    for (final row in medicines) {
      for (final ctrl in row.values) {
        ctrl.dispose();
      }
    }
    for (final ctrl in testControllers) {
      ctrl.dispose();
    }
    super.onClose();
  }
}
