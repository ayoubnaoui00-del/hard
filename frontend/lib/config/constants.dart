import 'package:flutter/foundation.dart';

class AppConstants {
  // Base API URLs
  // For Android emulator: 10.0.2.2
  // For iOS simulator / Web / Desktop: localhost
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      default:
        return 'http://localhost:3000/api';
    }
  }

  // Storage Keys
  static const String tokenKey = 'gymtrack_auth_token';
  static const String refreshTokenKey = 'gymtrack_refresh_token';
  static const String userKey = 'gymtrack_user_data';

  // App Metadata
  static const String appName = 'GymTrack';
  static const String appVersion = '1.0.0';
}
