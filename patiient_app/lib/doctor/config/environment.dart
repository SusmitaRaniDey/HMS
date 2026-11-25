// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:flutter/foundation.dart';

class Environment {
  // Base URL - Update this with your backend API URL
  // For Android Emulator: http://10.0.2.2:3000/api/v1
  // For iOS Simulator: http://localhost:3000/api/v1
  // For Real Device: http://YOUR_IP:3000/api/v1

  // -------------------------------------------------------
  // Change this flag to switch between emulator and device.
  // Use --dart-define=USE_EMULATOR=true for emulator.
  // Default is false for real physical devices.
  // -------------------------------------------------------
  static const bool _useEmulator = bool.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: false,
  );
  static const String _realDeviceIp = '192.168.1.102';
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (kIsWeb) return 'http://$_realDeviceIp:3000/api/v1';
    if (_useEmulator) {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
      if (Platform.isIOS || Platform.isMacOS) {
        return 'http://localhost:3000/api/v1';
      }
    }
    return 'http://$_realDeviceIp:3000/api/v1';
  }

  static String? resolveMediaUrl(dynamic value) {
    final path = value?.toString().trim();
    if (path == null || path.isEmpty) return null;
    final parsed = Uri.tryParse(path.replaceAll('\\', '/'));
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed.toString();
    final api = Uri.parse(baseUrl);
    return api
        .replace(path: '', query: null, fragment: null)
        .resolve(path.startsWith('/') ? path.substring(1) : path)
        .toString();
  }

  // API Endpoints - Doctor
  static const String AUTH_LOGIN = '/doctor/auth/login';

  static const String PROFILE = '/doctor/profile';
  static const String PROFILE_CHANGE_PASSWORD =
      '/doctor/profile/change-password';

  static const String APPOINTMENTS = '/doctor/appointments';
  static const String APPOINTMENTS_PENDING = '/doctor/appointments/pending';
  static const String APPOINTMENTS_CANCELLED = '/doctor/appointments/cancelled';
  static const String APPOINTMENTS_CONFIRMED = '/doctor/appointments/confirmed';
  static const String APPOINTMENTS_TODAY = '/doctor/appointments/today';
  static const String APPOINTMENTS_UPCOMING = '/doctor/appointments/upcoming';
  static const String APPOINTMENTS_HISTORY = '/doctor/appointments/history';

  // Appointment Detail
  static String appointmentDetail(int id) => '/doctor/appointments/$id';

  // Timeout
  static const int CONNECT_TIMEOUT = 60000; // 60 seconds
  static const int RECEIVE_TIMEOUT = 60000; // 60 seconds

  // Storage Keys
  static const String TOKEN_KEY = 'auth_token';
  static const String DOCTOR_KEY = 'doctor_data';

  // Pagination
  static const int DEFAULT_PAGE_SIZE = 20;
}
