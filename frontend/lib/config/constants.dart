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

  static String get baseHostUrl {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  /// Resolves relative media paths (e.g. /media/exercises/...) to absolute URLs
  /// with emulator/web-aware host translation.
  static String? resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    var resolved = path.trim();
    if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
      final cleanPath = resolved.startsWith('/') ? resolved : '/$resolved';
      resolved = '$baseHostUrl$cleanPath';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && resolved.contains('localhost')) {
      resolved = resolved.replaceAll('localhost', '10.0.2.2');
    }
    return resolved;
  }

  // Storage Keys
  static const String tokenKey = 'gymtrack_auth_token';
  static const String refreshTokenKey = 'gymtrack_refresh_token';
  static const String userKey = 'gymtrack_user_data';

  // App Metadata
  static const String appName = 'Hard';
  static const String appVersion = '1.0.0';
}
