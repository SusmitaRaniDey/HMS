import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class Environment {
  // API Configuration
  // Use the correct address for the current device type.
  // - Android emulator: 10.0.2.2
  // - iOS simulator: localhost
  // - Physical device: use your computer IP on the same network
  static final String BASE_URL = _getBaseUrl();

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

  // -------------------------------------------------------
  // Production / staging override.
  // Pass --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
  // when building a release to point the app at a real HTTPS server
  // without touching source code. When not provided, falls back to the
  // existing emulator/LAN dev behavior below.
  // -------------------------------------------------------
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String _getBaseUrl() {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    if (kIsWeb) {
      return 'http://$_realDeviceIp:3000/api/v1';
    }
    if (_useEmulator) {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
      if (Platform.isIOS) return 'http://localhost:3000/api/v1';
    }
    return 'http://$_realDeviceIp:3000/api/v1';
  }

  static String? resolveMediaUrl(dynamic value) {
    final path = value?.toString().trim();
    if (path == null || path.isEmpty) return null;
    final parsed = Uri.tryParse(path.replaceAll('\\', '/'));
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed.toString();
    final api = Uri.parse(BASE_URL);
    return api
        .replace(path: '', query: null, fragment: null)
        .resolve(path.startsWith('/') ? path.substring(1) : path)
        .toString();
  }

  // Timeouts
  static const int CONNECTION_TIMEOUT = 30000; // 30 seconds
  static const int RECEIVE_TIMEOUT = 30000; // 30 seconds

  // Storage Keys
  static const String TOKEN_KEY = 'auth_token';
  static const String PATIENT_KEY = 'patient_data';

  // API Endpoints
  static const String AUTH_REGISTER_EMAIL = '/patient/auth/register-email';
  static const String AUTH_REGISTER_PHONE = '/patient/auth/register-phone';
  static const String AUTH_LOGIN = '/patient/auth/login';

  static const String PROFILE = '/patient/profile';
  static const String PROFILE_CHANGE_PASSWORD =
      '/patient/profile/change-password';

  static const String DOCTORS = '/patient/doctors';
  static const String APPOINTMENTS = '/patient/appointments';
  static const String APPOINTMENTS_UPCOMING = '/patient/appointments/upcoming';
  static const String APPOINTMENTS_HISTORY = '/patient/appointments/history';
  static String appointmentMeetingJoin(int id) =>
      '/patient/appointments/$id/join-meeting';

  static const String DIAGNOSTICS = '/patient/diagnostics';
  static const String DIAGNOSTICS_CATEGORIES =
      '/patient/diagnostics/categories';
  static String diagnosticByItemCode(String itemCode) =>
      '/patient/diagnostics/item/$itemCode';
  static const String BOOKINGS = '/patient/bookings';
  static const String BOOKINGS_UPCOMING = '/patient/bookings/upcoming';
  static const String BOOKINGS_HISTORY = '/patient/bookings/history';

  // App Configuration
  static const String APP_NAME = 'Hospital Patient App';
  static const String APP_VERSION = '1.0.0';

  // Pagination
  static const int DEFAULT_PAGE_SIZE = 20;
  static const int APPOINTMENTS_PAGE_SIZE = 10;
  static const int BOOKINGS_PAGE_SIZE = 10;
}
