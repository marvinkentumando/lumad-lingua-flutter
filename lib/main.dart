import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

import 'services/offline_service.dart';
import 'services/notification_service.dart';
import 'widgets/error_boundary.dart';
import 'providers/theme_provider.dart';
import 'providers/router_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 9: True Edge-to-Edge UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Error Boundary
  GlobalErrorBoundary.init();

  final offlineService = OfflineService();

  // Initialize Services in parallel or robustly
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv Load Error: $e");
  }

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint("Supabase Initialization Error: $e");
  }

  try {
    await offlineService.init();
    await NotificationService().init();
  } catch (e) {
    debugPrint("Service Initialization Error: $e");
  }

  runApp(
    ProviderScope(
      overrides: [offlineServiceProvider.overrideWithValue(offlineService)],
      child: const LumadLinguaApp(),
    ),
  );
}

class LumadLinguaApp extends ConsumerWidget {
  const LumadLinguaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final brightness =
        themeMode == ThemeMode.system
            ? MediaQuery.platformBrightnessOf(context)
            : (themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp.router(
        title: 'Lumad Lingua',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final data = MediaQuery.of(context);
          return MediaQuery(
            data: data.copyWith(
              textScaler: data.textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.3,
              ),
            ),
            child: AnimatedTheme(
              data: brightness == Brightness.dark
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
