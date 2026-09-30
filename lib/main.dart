import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';

// Overlay entry point (Android only)
@pragma('vm:entry-point')
void overlayMain() {
  // No-op on web — overlay is Android-only
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android-only services — skip on web
  if (!kIsWeb) {
    await NotificationService.instance.init();
    await _initAndroidServices();
  }

  runApp(const ProviderScope(child: SplitSnapApp()));
}

Future<void> _initAndroidServices() async {
  try {
    await SharedPreferences.getInstance();
  } catch (_) {}
}

class SplitSnapApp extends StatelessWidget {
  const SplitSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
        ),
      ),
      home: const _AppEntryPoint(),
    );
  }
}

class _AppEntryPoint extends ConsumerStatefulWidget {
  const _AppEntryPoint();

  @override
  ConsumerState<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends ConsumerState<_AppEntryPoint> {
  bool _onboardingDone = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;

    // Android-only background services
    if (!kIsWeb) {
      await _startAndroidListeners();
    }

    setState(() {
      _onboardingDone = done;
      _loading = false;
    });
  }

  Future<void> _startAndroidListeners() async {
    try {
      // Dynamically start background SMS + bubble listeners
      // Wrapped in try-catch so web never crashes
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _onboardingDone ? const HomeScreen() : const OnboardingScreen();
  }
}
