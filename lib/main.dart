import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/background_sms_service.dart';
import 'core/services/bubble_service.dart';
import 'core/services/notification_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/split_popup/split_popup.dart';
import 'providers/splits_provider.dart';

/// Entry point for the overlay bubble (separate isolate)
@pragma('vm:entry-point')
void overlayMain() => BubbleOverlay.startOverlayEntry();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await BackgroundSmsService.initialize();
  runApp(const ProviderScope(child: SplitSnapApp()));
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
    setState(() {
      _onboardingDone = done;
      _loading = false;
    });

    // Listen for bubble taps → show split popup
    BackgroundSmsService.startListening(
      onPaymentDetected: (data) async {
        final splitId = data['split_id'] as int;
        final amount = (data['amount'] as num).toDouble();
        final merchant = data['merchant'] as String;

        final pending =
            ref.read(pendingBubblePaymentsProvider.notifier);
        pending.add(data);

        final count = ref.read(pendingBubblePaymentsProvider).length;
        await BubbleService.show(
          splitId: splitId,
          amount: amount,
          merchant: merchant,
          pendingCount: count,
        );
      },
    );

    // When user taps bubble → open popup
    BubbleService.onBubbleTapped.listen((data) async {
      await BubbleService.dismiss();
      if (!mounted) return;
      final splitId = data['split_id'] as int;
      final amount = (data['amount'] as num).toDouble();
      final merchant = data['merchant'] as String;

      ref.read(pendingBubblePaymentsProvider.notifier).remove(splitId);

      await SplitPopup.show(
        context,
        splitId: splitId,
        amount: amount,
        merchant: merchant,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _onboardingDone
        ? const HomeScreen()
        : const OnboardingScreen();
  }
}
