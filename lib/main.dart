import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studentos/app/student_os_app.dart';
import 'package:studentos/core/api/api_client.dart';
import 'package:studentos/core/storage/preferences_provider.dart';
import 'package:studentos/firebase_options.dart';

const _googleServerClientId =
    '175650710387-k3pi80ngo3hleommif4111dr2jb0n051.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env", isOptional: true);
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ApiClient.instance.init();
  await GoogleSignIn.instance.initialize(serverClientId: _googleServerClientId);
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const StudentOsApp(),
    ),
  );
}
