import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../core/config/env.dart';
import 'firebase_options.dart';

/// Initializes platform services before [runApp].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    FlutterNativeSplash.remove();
  } catch (_) {
    // Graceful fallback in non-native or headless test environments
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Ensure high-contrast white system status bar icons (battery, clock, wifi)
  // across edge-to-edge transparent ambient dark background.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0B1120),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Color(0x00000000),
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics is not supported on web; skip it there to avoid crashing at
  // startup.
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !Env.isRelease,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }
}
