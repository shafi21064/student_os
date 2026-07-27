import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Read from dart-define for web
const String baseUrlFromDefine = String.fromEnvironment('BASE_URL');
const String baseUrlWebFromDefine = String.fromEnvironment('BASE_URL_WEB');

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
}
