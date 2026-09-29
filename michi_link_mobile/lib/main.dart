import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/bootstrap.dart';
import 'package:michi_link_mobile/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the default options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const currentEnv = Environment.prod;

  // Setup service locator
  setupServiceLocator(currentEnv);

  if (kDebugMode) {
    await dotenv.load();
  }

  // Initialize services and plugins in parallel
  final performance = getIt<PerformanceService>();
  final trace = performance.startTrace('app_initialization');
  await Future.wait([getIt<LocalStorageService>().initialize()]);
  performance.stopTrace(trace);

  // Bootstrap the app
  await bootstrap(() => const AppPage());
}
