import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/diagnostic_model.dart';
import '../../data/providers/booking_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

// Full detail view for a test panel (one unique item_code). Book Now lives
// only on this screen — the list screen stays clean and uncluttered.
class DiagnosticDetailScreen extends StatefulWidget {
  const DiagnosticDetailScreen({super.key});

  @override
  State<DiagnosticDetailScreen> createState() => _DiagnosticDetailScreenState();
}

class _DiagnosticDetailScreenState extends State<DiagnosticDetailScreen> {
  final BookingProvider _provider = BookingProvider();

  bool _isLoading = true;
  String? _error;
  DiagnosticDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final args = Get.arguments;
    try {
      DiagnosticDetailModel detail;
      if (args is DiagnosticGroupModel) {
        if (args.itemCode != null && args.itemCode!.isNotEmpty) {
          detail = await _provider.getDiagnosticByItemCode(args.itemCode!);
        } else {
          // Standalone row with no item_code — nothing further to fetch.
          detail = DiagnosticDetailModel.fromGroup(args);
        }
      } else if (args is DiagnosticDetailModel) {
        detail = args;
      } else {
        setState(() {
          _error = 'This diagnostic test could not be found.';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHero = !_isLoading && _error == null && _detail != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: showHero,
      appBar: showHero
          ? null
          : AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              title: const Text('Test Details', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      body: showHero ? _buildBody() : SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading test details...');
    }

    if (_error != null || _detail == null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Unable to load test',
        message: _error ?? 'Something went wrong. Please try again.',
        buttonText: 'Retry',
        onButtonPressed: _load,
      );
    }

    final diagnostic = _detail!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(diagnostic),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.apartment_rounded,
                        title: 'Department',
                        value: diagnostic.category,
                        badgeColor: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.payments_rounded,
                        title: 'Price',
                        value: diagnostic.priceText,
                        badgeColor: AppColors.success,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 28.h),

                // Book Now — only shown on the details screen.
                CustomButton(
                  text: 'Book This Test',
                  icon: Icons.calendar_today,
                  color: AppColors.error,
                  onPressed: () => Get.toNamed(
                    AppRoutes.BOOK_DIAGNOSTIC,
                    arguments: diagnostic,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined, size: 15.sp, color: AppColors.textTertiary),
                    SizedBox(width: 6.w),
                    Text(
                      'Secure booking, confirmed instantly',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DiagnosticDetailModel diagnostic) {
    final topInset = MediaQuery.of(Get.context!).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, topInset + 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Test Details',
                  style: AppTextStyles.h5.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(26.r),
            ),
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: diagnostic.image != null && diagnostic.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Image.network(
                        diagnostic.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.monitor_heart_outlined,
                          size: 40.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Icon(Icons.monitor_heart_outlined, size: 40.sp, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            diagnostic.testName,
            style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _HeaderChip(icon: Icons.category_outlined, label: diagnostic.category),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38.w,
          height: 38.w,
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.body3.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color badgeColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20.sp, color: badgeColor),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

