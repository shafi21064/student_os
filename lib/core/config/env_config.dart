import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Read from dart-define for web
const String baseUrlFromDefine = String.fromEnvironment('BASE_URL');
const String baseUrlWebFromDefine = String.fromEnvironment('BASE_URL_WEB');
const String kireiBaseUrlFromDefine = String.fromEnvironment('KIREI_BASE_URL');
const String googleClientIdFromDefine = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
);
const String _defaultGoogleClientId =
    '562871577584-ufj2pqmleikmmpplvoun31dfurf99g99.apps.googleusercontent.com';

class EnvConfig {
  EnvConfig._();

  /// API base URL
  static String get baseUrl {
    if (kIsWeb) {
      return baseUrlFromDefine.isNotEmpty
          ? baseUrlFromDefine
          : 'https://default-api-url.com'; // fallback
    } else {
      return dotenv.env['BASE_URL'] ?? 'https://default-api-url.com';
    }
  }

  /// Web frontend base URL
  static String get baseUrlWeb {
    if (kIsWeb) {
      return baseUrlWebFromDefine.isNotEmpty
          ? baseUrlWebFromDefine
          : 'https://default-web-url.com'; // fallback
    } else {
      return dotenv.env['BASE_URL_WEB'] ?? 'https://default-web-url.com';
    }
  }

  static String get kireiBaseUrl {
    if (kIsWeb) {
      return kireiBaseUrlFromDefine.isNotEmpty
          ? kireiBaseUrlFromDefine
          : 'https://frontendapi.kireibd.com/api/v2';
    } else {
      return dotenv.env['KIREI_BASE_URL'] ??
          'https://frontendapi.kireibd.com/api/v2';
    }
  }

  static String get googleClientId {
    if (kIsWeb) {
      final value = _cleanEnvValue(googleClientIdFromDefine);
      return value.isEmpty ? _defaultGoogleClientId : value;
    }
    final value = _cleanEnvValue(dotenv.env['GOOGLE_CLIENT_ID'] ?? '');
    return value.isEmpty ? _defaultGoogleClientId : value;
  }

  static String _cleanEnvValue(String value) {
    final trimmed = value.trim();
    if (trimmed == '""' || trimmed == "''") return '';
    return trimmed;
  }
}
