import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/diagnostics_controller.dart';
import '../../models/diagnostic_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';

class DiagnosticsListScreen extends StatelessWidget {
  const DiagnosticsListScreen({super.key});

  static const _clinicalBlue = Color(0xFF2563EB);
  static const _clinicalTeal = Color(0xFF0F766E);
  static const _pageBackground = Color(0xFFF4F8FB);
  static const _navy = Color(0xFF16324F);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DiagnosticsController>();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/diagnostics'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(controller),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: _clinicalBlue),
                      );
                    }
                    if (controller.filteredDiagnosticGroups.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildDiagnosticsTable(controller);
                  }),
                ),
                Obx(
                  () => controller.total.value == 0
                      ? const SizedBox.shrink()
                      : _buildPagination(controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(DiagnosticsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(28.w, 20.h, 28.w, 20.h),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5EDF4))),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeading(controller),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(child: _buildSearchField(controller)),
                        SizedBox(width: 12.w),
                        _buildAddButton(),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildHeading(controller)),
                    SizedBox(width: 24.w),
                    SizedBox(
                      width: 330.w,
                      child: _buildSearchField(controller),
                    ),
                    SizedBox(width: 12.w),
                    _buildAddButton(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeading(DiagnosticsController controller) {
    return Row(
      children: [
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
          child: Icon(Icons.biotech_rounded, color: Colors.white, size: 23.sp),
        ),
        SizedBox(width: 14.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diagnostics Management',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 23.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              SizedBox(height: 4.h),
              Obx(
                () => Text(
                  '${controller.total.value} tests • '
                  '${controller.totalParameters.value} parameters total',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(DiagnosticsController controller) {
    return SizedBox(
      height: 46.h,
      child: TextField(
        onChanged: controller.searchDiagnostics,
        style: TextStyle(fontSize: 14.5.sp, color: _navy),
        decoration: InputDecoration(
          hintText: 'Search by test, category or item code',
          hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontSize: 14.sp),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF64748B),
            size: 21.sp,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFDCE6EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: _clinicalTeal, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 46.h,
      child: ElevatedButton.icon(
        onPressed: () => Get.toNamed('/diagnostics/add'),
        icon: Icon(Icons.add_rounded, size: 20.sp),
        label: const Text('Add Test'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _clinicalTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticsTable(DiagnosticsController controller) {
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
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: availableWidth),
                    child: DataTable(
                  showCheckboxColumn: false,
                  horizontalMargin: 24.w,
                  columnSpacing: constraints.maxWidth > 1250 ? 44.w : 28.w,
                  headingRowHeight: 58.h,
                  dataRowMinHeight: 72.h,
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
                    DataColumn(label: _TableHeading('SL')),
                    DataColumn(label: _TableHeading('ITEM CODE')),
                    DataColumn(label: _TableHeading('TEST NAME')),
                    DataColumn(label: _TableHeading('CATEGORY')),
                    DataColumn(label: _TableHeading('PRICE')),
                    DataColumn(label: _TableHeading('PARAMETERS')),
                    DataColumn(label: _TableHeading('ACTION')),
                  ],
                  rows: controller.filteredDiagnosticGroups.asMap().entries.map((
                    entry,
                  ) {
                    final sl =
                        (controller.page.value - 1) * controller.pageSize.value +
                        entry.key +
                        1;
                    final test = entry.value;
                    return DataRow(
                      onSelectChanged: (_) => _openParameters(test),
                      cells: [
                        DataCell(
                          Text(
                            '$sl',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(_ItemCodeChip(code: test.itemCode)),
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 220.w),
                            child: Text(
                              test.testName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _navy,
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(_CategoryBadge(label: test.category)),
                        DataCell(
                          Text(
                            test.price != null
                                ? '৳${test.price!.toStringAsFixed(0)}'
                                : '—',
                            style: TextStyle(
                              color: _clinicalTeal,
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DataCell(
                          _ParameterCountBadge(count: test.parameterCount),
                        ),
                        DataCell(
                          Tooltip(
                            message: 'View ${test.parameterCount} parameter(s)',
                            child: InkWell(
                              onTap: () => _openParameters(test),
                              borderRadius: BorderRadius.circular(9.r),
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: _clinicalBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(9.r),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _clinicalBlue,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                    ),
                  ),
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
                Icons.biotech_outlined,
                size: 36.sp,
                color: _clinicalTeal,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'No diagnostic tests found',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try a different search or add a new test.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  void _openParameters(DiagnosticGroupModel test) {
    Get.toNamed('/diagnostics/parameters', arguments: test);
  }

  Widget _buildPagination(DiagnosticsController controller) {
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5EDF4))),
        ),
        child: Row(
          children: [
            Text(
              'Rows per page: ',
              style: TextStyle(fontSize: 13.sp, color: _navy),
            ),
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
              '${controller.total.value} tests',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
            SizedBox(width: 12.w),
            OutlinedButton.icon(
              onPressed:
                  controller.page.value > 1 ? controller.previousPage : null,
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

class _ItemCodeChip extends StatelessWidget {
  final String? code;

  const _ItemCodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    if (code == null || code!.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        code!,
        style: TextStyle(
          color: const Color(0xFF475569),
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;

  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF2563EB),
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ParameterCountBadge extends StatelessWidget {
  final int count;

  const _ParameterCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0F766E);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.list_alt_rounded, size: 13.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            '$count ${count == 1 ? 'parameter' : 'parameters'}',
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
