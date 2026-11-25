import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../config/api_endpoints.dart';
import '../../models/refund_request_model.dart';
import '../../routes/admin_routes.dart';
import '../../services/api_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';

class RefundRequestsScreen extends StatefulWidget {
  const RefundRequestsScreen({super.key});

  @override
  State<RefundRequestsScreen> createState() => _RefundRequestsScreenState();
}

class _RefundRequestsScreenState extends State<RefundRequestsScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  var _status = 'all';
  var _isLoading = false;
  List<RefundRequestModel> _refunds = [];

  final _filters = const ['all', 'pending', 'processing', 'refunded', 'rejected'];

  @override
  void initState() {
    super.initState();
    _loadRefunds();
  }

  Future<void> _loadRefunds() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        ApiEndpoints.ADMIN_REFUNDS,
        queryParameters: _status == 'all' ? null : {'status': _status},
      );
      _refunds = (response.data as List)
          .map((json) => RefundRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to load refunds',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markProcessing(int id) async {
    await _apiService.patch(ApiEndpoints.adminRefundProcessing(id));
    await _loadRefunds();
    Helpers.showSuccessSnackbar('Success', 'Refund marked as processing');
  }

  Future<void> _processRefund(RefundRequestModel refund) async {
    final amountController = TextEditingController(
      text: refund.originalAmount?.toStringAsFixed(0) ?? '',
    );
    final txController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Process Refund'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Refunded amount',
                    helperText: refund.originalAmount != null
                        ? 'Cannot exceed original payment of BDT ${refund.originalAmount!.toStringAsFixed(0)}'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null) return 'Enter a valid amount';
                    if (amount <= 0) return 'Amount must be greater than zero';
                    if (refund.originalAmount != null &&
                        amount > refund.originalAmount!) {
                      return 'Cannot exceed original amount of BDT ${refund.originalAmount!.toStringAsFixed(0)}';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: txController,
                  decoration: const InputDecoration(
                    labelText: 'Refund transaction ID',
                    border: OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Transaction ID is required'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  setState(() {});
                  return;
                }
                Get.back(result: true);
              },
              child: const Text('Process'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null ||
        txController.text.trim().isEmpty ||
        amount <= 0 ||
        (refund.originalAmount != null && amount > refund.originalAmount!)) {
      Helpers.showErrorSnackbar(
        'Error',
        'Enter a valid amount (not exceeding the original payment) and transaction ID',
      );
      return;
    }

    await _apiService.patch(
      ApiEndpoints.adminRefundProcess(refund.id),
      data: {
        'refundedAmount': amount,
        'refundTransactionId': txController.text.trim(),
      },
    );
    await _loadRefunds();
    Helpers.showSuccessSnackbar('Success', 'Refund processed');
  }

  Future<void> _rejectRefund(RefundRequestModel refund) async {
    final reasonController = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reject Refund'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (reasonController.text.trim().isEmpty) {
      Helpers.showErrorSnackbar('Error', 'Enter rejection reason');
      return;
    }
    await _apiService.patch(
      ApiEndpoints.adminRefundReject(refund.id),
      data: {'rejectionReason': reasonController.text.trim()},
    );
    await _loadRefunds();
    Helpers.showSuccessSnackbar('Success', 'Refund rejected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: AdminRoutes.REFUNDS),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _refunds.isEmpty
                          ? const Center(child: Text('No refund requests found'))
                          : ListView.separated(
                              padding: EdgeInsets.all(24.w),
                              itemCount: _refunds.length,
                              separatorBuilder: (_, __) => SizedBox(height: 12.h),
                              itemBuilder: (_, index) => _buildRefundCard(_refunds[index]),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_return_rounded, color: AppColors.primary, size: 28.sp),
          SizedBox(width: 12.w),
          Text('Refund Requests', style: AppTextStyles.h2),
          const Spacer(),
          IconButton(
            onPressed: _loadRefunds,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
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
      child: Wrap(
        spacing: 8.w,
        children: _filters.map((status) {
          return FilterChip(
            selected: _status == status,
            label: Text(_statusLabel(status)),
            onSelected: (_) {
              setState(() => _status = status);
              _loadRefunds();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRefundCard(RefundRequestModel refund) {
    final date = refund.requestedAt != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(refund.requestedAt!))
        : 'N/A';
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  refund.patientName,
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _badge(refund.status),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            runSpacing: 8.h,
            spacing: 24.w,
            children: [
              _item('Amount', 'BDT ${refund.originalAmount?.toStringAsFixed(0) ?? 'N/A'}'),
              _item('Payment', refund.paymentMethod ?? 'N/A'),
              _item('Refund account', refund.refundToAccount),
              _item('Reason', refund.reasonLabel),
              _item('Date', date),
            ],
          ),
          if (refund.patientNote?.isNotEmpty == true) ...[
            SizedBox(height: 10.h),
            Text(refund.patientNote!, style: AppTextStyles.body2),
          ],
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            children: [
              if (refund.status == 'pending')
                OutlinedButton(
                  onPressed: () => _markProcessing(refund.id),
                  child: const Text('Mark as Processing'),
                ),
              if (refund.status == 'pending' || refund.status == 'processing')
                ElevatedButton(
                  onPressed: () => _processRefund(refund),
                  child: const Text('Process Refund'),
                ),
              if (refund.status == 'pending' || refund.status == 'processing')
                TextButton(
                  onPressed: () => _rejectRefund(refund),
                  child: const Text('Reject'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
    return SizedBox(
      width: 220.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 3.h),
          Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _badge(String status) {
    final color = switch (status) {
      'processing' => AppColors.info,
      'refunded' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.pending,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        _statusLabel(status),
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status == 'all') return 'All';
    return status[0].toUpperCase() + status.substring(1);
  }
}
