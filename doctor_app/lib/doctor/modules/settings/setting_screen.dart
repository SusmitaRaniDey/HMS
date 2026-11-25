import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Storage keys for the settings persisted below. These flags are saved
  // locally so the toggles are honest about their own state (no snap-back
  // on rebuild) even though the features they describe (push notification
  // delivery, email delivery, auto-accept logic) are not wired up yet -
  // there is no push SDK / backend support for them in this app.
  static const _kPushNotifications = 'settings_push_notifications';
  static const _kEmailNotifications = 'settings_email_notifications';
  static const _kAutoAccept = 'settings_auto_accept_appointments';

  final StorageService _storage = Get.find<StorageService>(tag: 'doctor');

  late bool _pushNotifications;
  late bool _emailNotifications;
  late bool _autoAccept;

  @override
  void initState() {
    super.initState();
    _pushNotifications =
        _storage.read<bool>(_kPushNotifications) ?? true;
    _emailNotifications =
        _storage.read<bool>(_kEmailNotifications) ?? false;
    _autoAccept = _storage.read<bool>(_kAutoAccept) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Settings')),
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
              value: _pushNotifications,
              onChanged: (value) {
                setState(() => _pushNotifications = value);
                _storage.write(_kPushNotifications, value);
              },
            ),
          ),
          _buildSettingsTile(
            title: 'Email Notifications',
            subtitle: 'Get updates via email',
            trailing: Switch(
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
                _storage.write(_kEmailNotifications, value);
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
              value: _autoAccept,
              onChanged: (value) {
                setState(() => _autoAccept = value);
                _storage.write(_kAutoAccept, value);
              },
            ),
          ),
          // Consultation duration is fixed for now — no picker exists, so
          // the tap/chevron affordance (which previously did nothing) has
          // been removed rather than left as dead UI.
          _buildSettingsTile(
            title: 'Consultation Duration',
            subtitle: '30 minutes',
          ),

          SizedBox(height: 24.h),

          // App Settings
          _buildSectionHeader('App Settings'),
          SizedBox(height: 12.h),
          // Only English is supported today — no language picker exists,
          // so the tap/chevron affordance has been removed.
          _buildSettingsTile(title: 'Language', subtitle: 'English'),
          // Dark mode isn't implemented — no theme picker exists, so the
          // tap/chevron affordance has been removed.
          _buildSettingsTile(title: 'Theme', subtitle: 'Light'),

          SizedBox(height: 24.h),

          // About
          _buildSectionHeader('About'),
          SizedBox(height: 12.h),
          _buildSettingsTile(title: 'Version', subtitle: '1.0.0'),
          // Terms of Service / Privacy Policy content isn't built yet — no
          // tap/chevron affordance since tapping would do nothing.
          _buildSettingsTile(title: 'Terms of Service'),
          _buildSettingsTile(title: 'Privacy Policy'),

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
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
