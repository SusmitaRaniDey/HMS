import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/medicine_controller.dart';
import '../../models/medicine_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';

class MedicineListScreen extends StatelessWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicineController>();
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/medicines'),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: Column(
                children: [
                  _header(controller),
                  Expanded(child: Obx(() => _content(controller))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(MedicineController controller) => Container(
    color: Colors.white,
    padding: EdgeInsets.all(24.w),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Management',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              'Manage all medicines',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 12.w,
          runSpacing: 10.h,
          children: [
            SizedBox(
              width: 310.w.clamp(220, 310).toDouble(),
              child: TextField(
                onChanged: controller.searchMedicines,
                decoration: InputDecoration(
                  hintText: 'Search name, company or DAR no...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showForm(controller),
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
              ),
            ),
          ],
        );
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              SizedBox(height: 16.h),
              actions,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            title,
            Flexible(child: actions),
          ],
        );
      },
    ),
  );

  Widget _content(MedicineController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 72.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 14.h),
            Text('No medicines found', style: AppTextStyles.h4),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 28.w,
                      columns: const [
                        DataColumn(label: Text('SL')),
                        DataColumn(label: Text('Company')),
                        DataColumn(label: Text('Trade Name')),
                        DataColumn(label: Text('Generic Name with Strength')),
                        DataColumn(label: Text('Dosage Form')),
                        DataColumn(label: Text('DAR No')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: controller.medicines
                          .map(
                            (medicine) => DataRow(
                              cells: [
                                DataCell(Text('${medicine.sl}')),
                                DataCell(_boundedText(medicine.company, 180)),
                                DataCell(_boundedText(medicine.tradeName, 180)),
                                DataCell(
                                  _boundedText(
                                    medicine.genericNameWithStrength,
                                    300,
                                  ),
                                ),
                                DataCell(
                                  _boundedText(medicine.dosageForm, 130),
                                ),
                                DataCell(Text(medicine.darNo)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'View',
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: () => _showDetails(medicine),
                                      ),
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.info,
                                        ),
                                        onPressed: () => _showForm(
                                          controller,
                                          medicine: medicine,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () =>
                                            controller.deleteMedicine(medicine),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          _pagination(controller),
        ],
      ),
    );
  }

  Widget _boundedText(String value, double width) => SizedBox(
    width: width.w,
    child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  Widget _pagination(MedicineController controller) => Obx(
    () => Row(
      children: [
        const Text('Rows per page: '),
        DropdownButton<int>(
          value: controller.pageSize.value,
          items: const [10, 25, 50, 100]
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value')),
              )
              .toList(),
          onChanged: controller.changePageSize,
        ),
        const Spacer(),
        Text(
          'Page ${controller.page.value} of ${controller.totalPages}  •  '
          '${controller.total.value} total',
        ),
        SizedBox(width: 12.w),
        OutlinedButton.icon(
          onPressed: controller.page.value > 1 ? controller.previousPage : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        SizedBox(width: 8.w),
        OutlinedButton.icon(
          onPressed: controller.page.value < controller.totalPages
              ? controller.nextPage
              : null,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
    ),
  );

  Future<void> _showForm(
    MedicineController controller, {
    MedicineModel? medicine,
  }) async {
    final formKey = GlobalKey<FormState>();
    final company = TextEditingController(text: medicine?.company);
    final tradeName = TextEditingController(text: medicine?.tradeName);
    final generic = TextEditingController(
      text: medicine?.genericNameWithStrength,
    );
    final dosage = TextEditingController(text: medicine?.dosageForm);
    final dar = TextEditingController(text: medicine?.darNo);
    await Get.dialog(
      AlertDialog(
        title: Text(medicine == null ? 'Add Medicine' : 'Edit Medicine'),
        content: SizedBox(
          width: 560.w,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(company, 'Company'),
                  _field(tradeName, 'Trade Name'),
                  _field(generic, 'Generic Name with Strength', maxLines: 2),
                  _field(dosage, 'Dosage Form'),
                  _field(dar, 'DAR Number'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () {
                      if (!formKey.currentState!.validate()) return;
                      controller.saveMedicine(
                        MedicineModel(
                          sl: medicine?.sl ?? 0,
                          company: company.text,
                          tradeName: tradeName.text,
                          genericNameWithStrength: generic.text,
                          dosageForm: dosage.text,
                          darNo: dar.text,
                        ),
                        editing: medicine != null,
                      );
                    },
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
    company.dispose();
    tradeName.dispose();
    generic.dispose();
    dosage.dispose();
    dar.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    ),
  );

  void _showDetails(MedicineModel medicine) => Get.dialog(
    AlertDialog(
      title: Text(medicine.tradeName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detail('SL', '${medicine.sl}'),
          _detail('Company', medicine.company),
          _detail(
            'Generic Name with Strength',
            medicine.genericNameWithStrength,
          ),
          _detail('Dosage Form', medicine.dosageForm),
          _detail('DAR No', medicine.darNo),
        ],
      ),
      actions: [TextButton(onPressed: Get.back, child: const Text('Close'))],
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text('$label: $value'),
  );
}
