import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/diagnostics_controller.dart';
import '../../models/diagnostic_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';

class DiagnosticParametersScreen extends StatefulWidget {
  const DiagnosticParametersScreen({super.key});

  @override
  State<DiagnosticParametersScreen> createState() =>
      _DiagnosticParametersScreenState();
}

class _DiagnosticParametersScreenState
    extends State<DiagnosticParametersScreen> {
  static const _clinicalBlue = Color(0xFF2563EB);
  static const _clinicalTeal = Color(0xFF0F766E);
  static const _pageBackground = Color(0xFFF4F8FB);
  static const _navy = Color(0xFF16324F);

  late final DiagnosticGroupModel test;
  late final DiagnosticsController controller;

  @override
  void initState() {
    super.initState();
    test = Get.arguments as DiagnosticGroupModel;
    controller = Get.find<DiagnosticsController>();
    _load();
  }

  Future<void> _load() async {
    if (test.itemCode != null && test.itemCode!.isNotEmpty) {
      await controller.loadParametersByItemCode(test.itemCode!);
    } else {
      // No item_code to group by — this is a standalone row.
      controller.parameterRows.value = [
        DiagnosticModel(
          id: test.id,
          category: test.category,
          testName: test.testName,
          price: test.price,
          isActive: test.isActive,
          image: test.image,
        ),
      ];
    }
  }

  Future<void> _deleteRow(DiagnosticModel row) async {
    final deleted = await controller.deleteDiagnostic(row.id!);
    if (deleted) {
      await _load();
      await controller.loadDiagnostics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/diagnostics'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingParameters.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: _clinicalBlue),
                      );
                    }
                    if (controller.parameterRows.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildParametersTable();
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 28.w, 20.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5EDF4))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: _navy,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_clinicalTeal, Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13.r),
              boxShadow: [
                BoxShadow(
                  color: _clinicalTeal.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.science_rounded,
              color: Colors.white,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.testName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _InfoChip(
                      icon: Icons.qr_code_2_rounded,
                      label: test.itemCode ?? 'No item code',
                    ),
                    _InfoChip(
                      icon: Icons.category_rounded,
                      label: test.category,
                    ),
                    if (test.price != null)
                      _InfoChip(
                        icon: Icons.payments_rounded,
                        label: '৳${test.price!.toStringAsFixed(0)}',
                        color: _clinicalTeal,
                      ),
                    Obx(
                      () => _InfoChip(
                        icon: Icons.list_alt_rounded,
                        label:
                            '${controller.parameterRows.length} ${controller.parameterRows.length == 1 ? 'parameter' : 'parameters'}',
                        color: _clinicalBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 850 ? 16.w : 28.w;
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24.h,
            horizontalPadding,
            24.h,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2EAF1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A16324F),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: availableWidth,
                  minHeight: constraints.maxHeight - 48.h,
                ),
                child: DataTable(
                  horizontalMargin: 24.w,
                  columnSpacing: constraints.maxWidth > 1250 ? 44.w : 28.w,
                  headingRowHeight: 54.h,
                  dataRowMinHeight: 64.h,
                  dataRowMaxHeight: 72.h,
                  dividerThickness: 1,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF1F7FB),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return const Color(0xFFF1FBF9);
                    }
                    return Colors.white;
                  }),
                  columns: const [
                    DataColumn(label: _TableHeading('ID')),
                    DataColumn(label: _TableHeading('PARAMETER')),
                    DataColumn(label: _TableHeading('NORMAL RANGE')),
                    DataColumn(label: _TableHeading('UNIT')),
                    DataColumn(label: _TableHeading('NOTES')),
                    DataColumn(label: _TableHeading('ACTIONS')),
                  ],
                  rows: controller.parameterRows.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '#${row.id}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 220.w),
                            child: Text(
                              row.parameter ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _navy,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            row.normalRange ?? '—',
                            style: TextStyle(
                              color: const Color(0xFF475569),
                              fontSize: 13.5.sp,
                            ),
                          ),
                        ),
                        DataCell(
                          row.unit != null && row.unit!.isNotEmpty
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 9.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    row.unit!,
                                    style: TextStyle(
                                      color: const Color(0xFF475569),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : Text(
                                  '—',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.sp,
                                  ),
                                ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 200.w),
                            child: Text(
                              row.notes ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionIconButton(
                                icon: Icons.edit_rounded,
                                color: _clinicalBlue,
                                tooltip: 'Edit',
                                onTap: () => Get.toNamed(
                                  '/diagnostics/edit',
                                  arguments: row,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              _ActionIconButton(
                                icon: Icons.delete_outline_rounded,
                                color: const Color(0xFFDC2626),
                                tooltip: 'Delete',
                                onTap: () => _deleteRow(row),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFE2EAF1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                color: _clinicalTeal.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.science_outlined,
                size: 36.sp,
                color: _clinicalTeal,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'No parameters found',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeading extends StatelessWidget {
  final String label;

  const _TableHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: const Color(0xFF587089),
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? const Color(0xFF64748B);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: resolvedColor),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: resolvedColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, color: color, size: 17.sp),
        ),
      ),
    );
  }
}
