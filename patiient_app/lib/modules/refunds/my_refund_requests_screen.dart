import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../data/models/refund_request_model.dart';
import '../../data/providers/refund_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MyRefundRequestsScreen extends StatefulWidget {
  const MyRefundRequestsScreen({super.key});

  @override
  State<MyRefundRequestsScreen> createState() => _MyRefundRequestsScreenState();
}

class _MyRefundRequestsScreenState extends State<MyRefundRequestsScreen> {
  final RefundProvider _provider = RefundProvider();
  late Future<List<RefundRequestModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _provider.getMine();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _provider.getMine();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Refund Requests')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<RefundRequestModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final refunds = snapshot.data ?? [];
            if (refunds.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(24.w),
                children: [
                  SizedBox(height: 120.h),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64.sp,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: Text(
                      'No refund requests yet',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: refunds.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) =>
                  _RefundCard(refund: refunds[index]),
            );
          },
        ),
      ),
    );
  }
}

class _RefundCard extends StatelessWidget {
  final RefundRequestModel refund;

  const _RefundCard({required this.refund});

  @override
  Widget build(BuildContext context) {
    final parsed = refund.requestedAt != null
        ? DateTime.tryParse(refund.requestedAt!)
        : null;
    final date = parsed != null
        ? DateFormat('dd MMM yyyy').format(parsed)
        : refund.requestedAt ?? 'N/A';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Appointment #${refund.appointmentId}',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _refundBadge(refund.status),
            ],
          ),
          SizedBox(height: 12.h),
          Text(refund.reasonLabel, style: AppTextStyles.body1),
          SizedBox(height: 8.h),
          Text(
            'Amount: BDT ${refund.originalAmount?.toStringAsFixed(0) ?? 'N/A'}',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Requested: $date',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _refundBadge(String status) {
    final color = switch (status) {
      'processing' => AppColors.info,
      'refunded' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        refund.statusLabel,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
