import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/diagnostics_controller.dart';
import '../../models/diagnostic_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/custom_textfield.dart';


class EditDiagnosticScreen extends StatelessWidget {
  EditDiagnosticScreen({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  void _handleSubmit(BuildContext context, DiagnosticsController controller, DiagnosticModel diagnostic) {
    if (_formKey.currentState!.validate()) {
      final updatedDiagnostic = DiagnosticModel(
        id: diagnostic.id,
        testName: controller.testNameController.text.trim(),
        category: controller.categoryController.text.trim(),
        itemCode: controller.itemCodeController.text.trim(),
        price: double.tryParse(controller.priceController.text.trim()),
        parameter: controller.parameterController.text.trim(),
        normalRange: controller.normalRangeController.text.trim(),
        unit: controller.unitController.text.trim(),
        notes: controller.notesController.text.trim(),
      );

      controller.updateDiagnostic(diagnostic.id!, updatedDiagnostic);
    }
  }


  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DiagnosticsController>();
    final diagnostic = Get.arguments as DiagnosticModel;
    // Pre-fill controller fields if not already set
    controller.testNameController.text = diagnostic.testName;
    controller.categoryController.text = diagnostic.category;
    controller.itemCodeController.text = diagnostic.itemCode ?? '';
    controller.priceController.text = diagnostic.price?.toString() ?? '';
    controller.parameterController.text = diagnostic.parameter ?? '';
    controller.normalRangeController.text = diagnostic.normalRange ?? '';
    controller.unitController.text = diagnostic.unit ?? '';
    controller.notesController.text = diagnostic.notes ?? '';

    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/diagnostics'),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.w),
                      child: Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Test Information',
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 24.h),

                              CustomTextField(
                                controller: controller.testNameController,
                                label: 'Test Name',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Test name is required';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.categoryController,
                                      label: 'Category',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Category is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.itemCodeController,
                                      label: 'Item Code',
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              CustomTextField(
                                controller: controller.priceController,
                                label: 'Price (৳)',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Price is required';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null) {
                                    return 'Enter valid amount';
                                  }
                                  if (price < 0) {
                                    return 'Price cannot be negative';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.parameterController,
                                      label: 'Parameter',
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.normalRangeController,
                                      label: 'Normal Range',
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.unitController,
                                      label: 'Unit',
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              CustomTextField(
                                controller: controller.notesController,
                                label: 'Notes',
                                maxLines: 3,
                              ),

                              SizedBox(height: 32.h),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 32.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  SizedBox(width: 16.w),
                                  ElevatedButton(
                                    onPressed: () => _handleSubmit(context, controller, diagnostic),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 32.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                    child: const Text('Update Test'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.all(24.w),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
          ),
          SizedBox(width: 16.w),
          Text(
            'Edit Diagnostic Test',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
