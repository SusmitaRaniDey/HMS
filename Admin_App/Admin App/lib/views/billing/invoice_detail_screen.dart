import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../config/api_endpoints.dart';
import '../../models/billing_model.dart';
import '../../services/api_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/helpers.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int billingId;

  const InvoiceDetailScreen({super.key, required this.billingId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  BillingModel? _billing;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        ApiEndpoints.billingById(widget.billingId),
      );
      _billing = BillingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      Helpers.showErrorSnackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to load invoice',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Uint8List> _fetchPdfBytes() async {
    final response = await _apiService.dio.get<List<int>>(
      ApiEndpoints.billingInvoicePdf(widget.billingId),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const <int>[]);
  }

  Future<void> _print() async {
    setState(() => _isBusy = true);
    try {
      final bytes = await _fetchPdfBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      Helpers.showErrorSnackbar('Error', 'Could not load the printable invoice');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _download() async {
    setState(() => _isBusy = true);
    try {
      final bytes = await _fetchPdfBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_billing?.invoiceNumber ?? 'invoice'}.pdf',
      );
    } catch (_) {
      Helpers.showErrorSnackbar('Error', 'Could not download the invoice');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Invoice', style: AppTextStyles.h4),
        actions: _billing == null
            ? null
            : [
                TextButton.icon(
                  onPressed: _isBusy ? null : _download,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download'),
                ),
                SizedBox(width: 8.w),
                ElevatedButton.icon(
                  onPressed: _isBusy ? null : _print,
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _billing == null
              ? const Center(child: Text('Invoice not found'))
              : Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 720.w),
                      child: _buildInvoiceCard(_billing!),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInvoiceCard(BillingModel billing) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHospitalHeader(billing),
          SizedBox(height: 28.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPatientInfo(billing)),
              SizedBox(width: 24.w),
              Expanded(child: _buildInvoiceInfo(billing)),
            ],
          ),
          SizedBox(height: 28.h),
          _buildBillingDetails(billing),
        ],
      ),
    );
  }

  Widget _buildHospitalHeader(BillingModel billing) {
    return Row(
      children: [
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.favorite_rounded, color: Colors.white, size: 26.sp),
        ),
        SizedBox(width: 14.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HealthGrid', style: AppTextStyles.h3),
            Text(
              'Payment Invoice · ${billing.billTypeLabel}',
              style: AppTextStyles.body2,
            ),
          ],
        ),
        const Spacer(),
        _statusBadge(billing.paymentStatus),
      ],
    );
  }

  Widget _buildPatientInfo(BillingModel billing) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BILLED TO',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          _kv('Name', billing.patientName),
          _kv('Patient ID', '#${billing.patientId}'),
          if (billing.patientPhone.isNotEmpty) _kv('Phone', billing.patientPhone),
          if (billing.patientEmail.isNotEmpty) _kv('Email', billing.patientEmail),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo(BillingModel billing) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVOICE',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          _kv('Invoice No.', billing.invoiceNumber ?? 'Pending'),
          _kv('Date', DateFormat('dd MMM yyyy').format(billing.invoiceDate)),
          _kv('Payment Method', billing.paymentMethodLabel),
          if (billing.transactionId?.isNotEmpty == true)
            _kv('Transaction ID', billing.transactionId!),
        ],
      ),
    );
  }

  Widget _buildBillingDetails(BillingModel billing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Billing Details', style: AppTextStyles.subtitle1.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        )),
        SizedBox(height: 8.h),
        const Divider(color: AppColors.border, height: 1),
        SizedBox(height: 12.h),
        _row(billing.description ?? billing.billTypeLabel,
            _money(billing.subtotal, billing.currency)),
        _row('Discount', '- ${_money(billing.discount, billing.currency)}'),
        _row('Tax', _money(billing.tax, billing.currency)),
        SizedBox(height: 8.h),
        const Divider(color: AppColors.border, height: 1),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppTextStyles.h4),
            Text(
              _money(billing.totalAmount, billing.currency),
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body1)),
          Text(value, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.body2,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.textSecondary)),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isPaid = status == 'completed';
    final color = isPaid ? AppColors.success : AppColors.pending;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isPaid ? 'PAID' : status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _money(double amount, String currency) =>
      '$currency ${amount.toStringAsFixed(0)}';
}
