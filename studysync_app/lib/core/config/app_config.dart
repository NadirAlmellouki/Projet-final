import 'package:flutter/foundation.dart';

/// Configuration API — URL adaptée à la plateforme.
///
/// Override au build :
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
class AppConfig {
  AppConfig._();

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) return 'http://localhost:3000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      default:
        return 'http://localhost:3000';
    }
  }

  static const String apiPrefix = '/api';

  /// Client OAuth Google (Web / iOS / Android).
  /// `flutter run --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com`
  static String? get googleClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_CLIENT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Secours dev (même ID que run_web.bat / web/index.html)
    if (kDebugMode) {
      return '493644909191-emg4n24h5emnc9g7kubii119igiqp31r.apps.googleusercontent.com';
    }
    return null;
  }
}
