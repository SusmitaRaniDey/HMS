import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          SizedBox(height: 12.h),
          _buildSettingsTile(
            title: 'Push Notifications',
            subtitle: 'Receive appointment notifications',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification toggle
              },
            ),
          ),
          _buildSettingsTile(
            title: 'Email Notifications',
            subtitle: 'Get updates via email',
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // TODO: Implement email notification toggle
              },
            ),
          ),

          SizedBox(height: 24.h),

          // Appointment Settings
          _buildSectionHeader('Appointment Settings'),
          SizedBox(height: 12.h),
          _buildSettingsTile(
            title: 'Auto-Accept Appointments',
            subtitle: 'Automatically accept new requests',
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // TODO: Implement auto-accept toggle
              },
            ),
          ),
          _buildSettingsTile(
            title: 'Consultation Duration',
            subtitle: '30 minutes',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
            onTap: () {
              // TODO: Show duration picker
            },
          ),

          SizedBox(height: 24.h),

          // App Settings
          _buildSectionHeader('App Settings'),
          SizedBox(height: 12.h),
          _buildSettingsTile(
            title: 'Language',
            subtitle: 'English',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
            onTap: () {
              // TODO: Show language picker
            },
          ),
          _buildSettingsTile(
            title: 'Theme',
            subtitle: 'Light',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
            onTap: () {
              // TODO: Show theme picker
            },
          ),

          SizedBox(height: 24.h),

          // About
          _buildSectionHeader('About'),
          SizedBox(height: 12.h),
          _buildSettingsTile(
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _buildSettingsTile(
            title: 'Terms of Service',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
            onTap: () {
              // TODO: Show terms
            },
          ),
          _buildSettingsTile(
            title: 'Privacy Policy',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: AppTextStyles.subtitle1.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}