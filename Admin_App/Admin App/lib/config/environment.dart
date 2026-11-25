import 'package:flutter/foundation.dart';
import '../utils/platform.dart';

class Environment {
  // API Configuration
  //
  // For a release/staging build, point the app at a real server without
  // touching source by passing:
  //   flutter build web --dart-define=API_BASE_URL=https://api.example.com/api/v1
  // If API_BASE_URL is not provided, falls back to the existing per-platform
  // loopback defaults used for local development.
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get BASE_URL {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    return _devDefaultBaseUrl;
  }

  static String get _devDefaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1'; // Web
    } else if (isAndroid) {
      return 'http://10.0.2.2:3000/api/v1'; // Android Emulator
    } else if (isIOS) {
      return 'http://localhost:3000/api/v1'; // iOS Simulator
    } else {
      // Windows, macOS, Linux Desktop
      return 'http://127.0.0.1:3000/api/v1'; // Use 127.0.0.1 for desktop
    }
  }

  /// Resolves API-relative media paths using the same host as the API.
  static String? resolveMediaUrl(dynamic value) {
    final path = value?.toString().trim();
    if (path == null || path.isEmpty) return null;
    final parsed = Uri.tryParse(path.replaceAll('\\', '/'));
    if (parsed == null) return null;
    if (parsed.hasScheme) {
      return parsed.toString();
    }
    final api = Uri.parse(BASE_URL);
    final origin = api.replace(path: '', query: null, fragment: null);
    return origin
        .resolve(path.startsWith('/') ? path.substring(1) : path)
        .toString();
  }

  static const String API_VERSION = 'v1';

  // Storage Keys
  static const String TOKEN_KEY = 'auth_token';
  static const String ADMIN_TOKEN_KEY = 'admin_token';
  static const String USER_KEY = 'user_data';
  static const String ADMIN_KEY = 'admin_data';
  static const String LANGUAGE_KEY = 'app_language';

  // App Info
  static const String APP_NAME = 'HealthGrid';
  static const String ADMIN_APP_NAME = 'HealthGrid';
  static const String APP_VERSION = '1.0.0';

  // Timeouts
  static const int CONNECTION_TIMEOUT = 30000;
  static const int RECEIVE_TIMEOUT = 30000;
}
