import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/appointment_model.dart';
import '../../data/providers/prescription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'prescription_form_controller.dart';

class PrescriptionFormScreen extends GetView<PrescriptionFormController> {
  const PrescriptionFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppointmentModel appointment = Get.arguments as AppointmentModel;
    final patientName = appointment.patient?.name ?? 'Patient';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Write Prescription'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 22.r,
                    child: Text(
                      patientName.isNotEmpty
                          ? patientName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Appointment #${appointment.id}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Patient Age
            _label('Patient Age'),
            _field(
              controller.patientAgeCtrl,
              hint: 'e.g. 35',
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 16.h),

            // Diagnosis
            _label('Diagnosis / Chief Complaint'),
            _field(
              controller.diagnosisCtrl,
              hint: 'Enter diagnosis...',
              maxLines: 2,
            ),

            SizedBox(height: 20.h),

            // Medicines
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prescribed Medicines',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.addMedicineRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Obx(
              () => Column(
                children: List.generate(
                  controller.medicines.length,
                  (i) => _medicineRow(i),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Tests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diagnostic Tests Suggested',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.addTestRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Obx(
              () => Column(
                children: List.generate(
                  controller.testControllers.length,
                  (i) => _testRow(i),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Notes
            _label("Doctor's Notes / Advice"),
            _field(
              controller.notesCtrl,
              hint: 'Enter notes or advice...',
              maxLines: 3,
            ),

            SizedBox(height: 32.h),

            // Submit button
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => controller.submit(appointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textWhite,
                          ),
                        )
                      : Text(
                          'Submit & Generate PDF',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                ),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(
      text,
      style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _field(
    TextEditingController ctrl, {
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
    ),
  );

  Widget _medicineRow(int index) {
    final row = controller.medicines[index];
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Medicine ${index + 1}',
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.remove_circle,
                  color: AppColors.error,
                  size: 20.sp,
                ),
                onPressed: () => controller.removeMedicineRow(index),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _MedicineAutocomplete(
            key: ObjectKey(row['name']),
            valueController: row['name']!,
            search: controller.searchMedicines,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _field(row['dose']!, hint: 'Dose')),
              SizedBox(width: 8.w),
              Expanded(child: _field(row['frequency']!, hint: 'Frequency')),
              SizedBox(width: 8.w),
              Expanded(child: _field(row['duration']!, hint: 'Duration')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _testRow(int index) {
    return Obx(
      () => _TestRowWidget(
        key: ValueKey('test_$index'),
        valueController: controller.testControllers[index],
        suggestions: controller.availableDiagnostics,
        onRemove: () => controller.removeTestRow(index),
      ),
    );
  }
}

class _MedicineAutocomplete extends StatefulWidget {
  const _MedicineAutocomplete({
    super.key,
    required this.valueController,
    required this.search,
  });

  final TextEditingController valueController;
  final Future<List<MedicineSuggestion>> Function(String query) search;

  @override
  State<_MedicineAutocomplete> createState() => _MedicineAutocompleteState();
}

class _MedicineAutocompleteState extends State<_MedicineAutocomplete> {
  bool _loading = false;
  int _requestId = 0;

  void _onChanged(String value) {
    widget.valueController.text = value;
  }

  Future<Iterable<MedicineSuggestion>> _loadOptions(String rawQuery) async {
    final query = rawQuery.trim();
    final requestId = ++_requestId;
    if (query.isEmpty) {
      if (mounted && _loading) setState(() => _loading = false);
      return const [];
    }

    if (mounted && !_loading) setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (requestId != _requestId) return const [];

    try {
      final results = await widget.search(query);
      if (requestId != _requestId) return const [];
      return results;
    } catch (_) {
      return const [];
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<MedicineSuggestion>(
      displayStringForOption: (option) => option.tradeName,
      optionsBuilder: (value) => _loadOptions(value.text),
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        if (fieldController.text.isEmpty &&
            widget.valueController.text.isNotEmpty) {
          fieldController.text = widget.valueController.text;
        }
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Type medicine name...',
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13.sp),
            suffixIcon: _loading
                ? Padding(
                    padding: EdgeInsets.all(13.w),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                    size: 18.sp,
                  ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(10.r),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560.w, maxHeight: 280.h),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.medication_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    option.tradeName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      option.genericName,
                      option.dosageForm,
                      option.company,
                    ].where((value) => value.isNotEmpty).join(' • '),
                  ),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: (option) {
        widget.valueController.text = option.tradeName;
        _requestId++;
      },
    );
  }
}

class _TestRowWidget extends StatelessWidget {
  const _TestRowWidget({
    super.key,
    required this.valueController,
    required this.suggestions,
    required this.onRemove,
  });

  final TextEditingController valueController;
  final List<String> suggestions;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: valueController.text),
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                if (query.isEmpty) return suggestions.take(8);
                return suggestions.where(
                  (name) => name.toLowerCase().contains(query),
                );
              },
              fieldViewBuilder: (context, fieldCtrl, focusNode, onSubmitted) {
                return TextField(
                  controller: fieldCtrl,
                  focusNode: focusNode,
                  onChanged: (val) => valueController.text = val,
                  decoration: InputDecoration(
                    hintText: 'Search or type test name...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13.sp,
                    ),
                    suffixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 18.sp,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10.r),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 220.h),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final option = options.elementAt(i);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                              valueController.text = option;
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.science_outlined,
                                    size: 16.sp,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(fontSize: 13.sp),
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
                );
              },
              onSelected: (value) => valueController.text = value,
            ),
          ),
          SizedBox(width: 8.w),
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: IconButton(
              icon: Icon(
                Icons.remove_circle,
                color: AppColors.error,
                size: 20.sp,
              ),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}
