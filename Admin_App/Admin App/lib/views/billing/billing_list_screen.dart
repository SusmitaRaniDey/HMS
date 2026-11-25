import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../config/api_endpoints.dart';
import '../../controller/billing_controller.dart';
import '../../models/billing_model.dart';
import '../../routes/admin_routes.dart';
import '../../services/api_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';
import 'invoice_detail_screen.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  final BillingController controller = Get.find<BillingController>();
  Timer? _searchDebounce;

  static const _billTypes = {
    'all': 'All Types',
    'appointment': 'Doctor Appointment',
    'online_consultation': 'Online Consultation',
    'emergency_consultation': 'Emergency Consultation',
    'diagnostic_booking': 'Diagnostic Booking',
    'other': 'Other',
  };

  static const _paymentStatuses = {
    'all': 'All Statuses',
    'completed': 'Paid',
    'pending': 'Pending',
    'failed': 'Failed',
    'cancelled': 'Cancelled',
  };

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      controller.search(value);
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          controller.dateFrom.value != null && controller.dateTo.value != null
              ? DateTimeRange(
                  start: controller.dateFrom.value!,
                  end: controller.dateTo.value!,
                )
              : null,
    );
    if (range != null) controller.filterByDateRange(range);
  }

  Future<Uint8List> _fetchPdfBytes(int id) async {
    final response = await Get.find<ApiService>().dio.get<List<int>>(
          ApiEndpoints.billingInvoicePdf(id),
          options: Options(responseType: ResponseType.bytes),
        );
    return Uint8List.fromList(response.data ?? const <int>[]);
  }

  Future<void> _downloadInvoice(BillingModel billing) async {
    try {
      final bytes = await _fetchPdfBytes(billing.id);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${billing.invoiceNumber ?? 'invoice_${billing.id}'}.pdf',
      );
    } catch (_) {
      Helpers.showErrorSnackbar('Error', 'Could not download the invoice');
    }
  }

  Future<void> _printInvoice(BillingModel billing) async {
    try {
      final bytes = await _fetchPdfBytes(billing.id);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      Helpers.showErrorSnackbar('Error', 'Could not load the printable invoice');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: AdminRoutes.BILLING),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildFilters(),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (controller.billings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 80.sp, color: AppColors.textHint),
                              SizedBox(height: 16.h),
                              Text('No invoices found', style: AppTextStyles.h4),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Expanded(child: _buildTable()),
                          _buildPagination(),
                        ],
                      );
                    }),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 26.sp),
                  SizedBox(width: 10.w),
                  Text('Billing & Invoices',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'All invoices generated automatically from successful payments',
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 280.w,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search invoice # or patient...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 12.h),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(width: 12.w),
              IconButton(
                onPressed: controller.fetchBilling,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                iconSize: 26.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      color: Colors.white,
      child: Obx(() => Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _dropdown(
                value: controller.billTypeFilter.value,
                items: _billTypes,
                onChanged: controller.filterByBillType,
              ),
              _dropdown(
                value: controller.paymentStatusFilter.value,
                items: _paymentStatuses,
                onChanged: controller.filterByPaymentStatus,
              ),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: Text(
                  controller.dateFrom.value != null && controller.dateTo.value != null
                      ? '${DateFormat('dd MMM').format(controller.dateFrom.value!)} - ${DateFormat('dd MMM yyyy').format(controller.dateTo.value!)}'
                      : 'Date range',
                ),
              ),
              if (controller.dateFrom.value != null)
                TextButton(
                  onPressed: controller.clearDateFilter,
                  child: const Text('Clear date'),
                ),
            ],
          )),
    );
  }

  Widget _dropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(() => DataTable(
                columns: [
                  DataColumn(label: Text('Invoice ID', style: AppTextStyles.subtitle1)),
                  DataColumn(label: Text('Patient', style: AppTextStyles.subtitle1)),
                  DataColumn(label: Text('Bill Type', style: AppTextStyles.subtitle1)),
                  DataColumn(label: Text('Amount', style: AppTextStyles.subtitle1)),
                  DataColumn(label: Text('Payment Method', style: AppTextStyles.subtitle1)),
                  DataColumn(label: Text('Payment Status', style: AppTextStyles.subtitle1)),
                  DataColumn(label: Text('Date', style: AppTextStyles.subtitle1)),
                  DataColumn(label: Text('Action', style: AppTextStyles.subtitle1)),
                ],
                rows: controller.billings.map((billing) {
                  return DataRow(cells: [
                    DataCell(Text(billing.invoiceNumber ?? '—')),
                    DataCell(Text(billing.patientName)),
                    DataCell(Text(billing.billTypeLabel)),
                    DataCell(Text('${billing.currency} ${billing.totalAmount.toStringAsFixed(0)}')),
                    DataCell(Text(billing.paymentMethodLabel)),
                    DataCell(_statusBadge(billing.paymentStatus)),
                    DataCell(Text(DateFormat('dd MMM yyyy').format(billing.invoiceDate))),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: AppColors.info),
                          tooltip: 'View',
                          onPressed: () => Get.to(
                              () => InvoiceDetailScreen(billingId: billing.id)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_outlined, color: AppColors.primary),
                          tooltip: 'Download',
                          onPressed: () => _downloadInvoice(billing),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print_outlined, color: AppColors.textSecondary),
                          tooltip: 'Print',
                          onPressed: () => _printInvoice(billing),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              )),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Obx(() {
      final page = controller.page.value;
      final totalPages = controller.totalPages;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${controller.total.value} invoice(s) total',
              style: AppTextStyles.body2,
            ),
            Row(
              children: [
                IconButton(
                  onPressed: page > 1 ? () => controller.goToPage(page - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('Page $page of $totalPages', style: AppTextStyles.body2),
                IconButton(
                  onPressed: page < totalPages ? () => controller.goToPage(page + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statusBadge(String status) {
    final isPaid = status == 'completed';
    final color = isPaid ? AppColors.success : AppColors.pending;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        isPaid ? 'Paid' : status.isEmpty
            ? 'N/A'
            : status[0].toUpperCase() + status.substring(1),
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
