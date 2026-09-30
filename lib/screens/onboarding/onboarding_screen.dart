import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  final _steps = const [
    _OnboardStep(
      emoji: '💸',
      title: 'Auto-detect payments',
      description:
          'SplitSnap reads your UPI SMS to instantly detect payments — no manual entry needed.',
      permission: null,
    ),
    _OnboardStep(
      emoji: '📱',
      title: 'SMS Access',
      description:
          'Allow SMS access so we can detect your UPI payments automatically.',
      permission: Permission.sms,
    ),
    _OnboardStep(
      emoji: '🟢',
      title: 'Floating Bubble',
      description:
          'A small private circle appears when you pay. Only you know what it is.',
      permission: null,
      isOverlay: true,
    ),
    _OnboardStep(
      emoji: '📍',
      title: 'Location',
      description:
          'We capture where you paid so you never forget the context.',
      permission: Permission.location,
    ),
    _OnboardStep(
      emoji: '👥',
      title: 'Contacts',
      description: 'Pick your friends from contacts when splitting.',
      permission: Permission.contacts,
    ),
    _OnboardStep(
      emoji: '🔔',
      title: 'Notifications',
      description:
          'Silent notification when a payment is auto-saved while you were busy.',
      permission: Permission.notification,
    ),
  ];

  Future<void> _handleStep() async {
    final step = _steps[_step];
    if (!kIsWeb) {
      if (step.isOverlay) {
        await FlutterOverlayWindow.requestPermission();
      } else if (step.permission != null) {
        await step.permission!.request();
      }
    }
    _nextStep();
  }

  void _nextStep() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;
    final isIntro = step.permission == null && !step.isOverlay;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _step
                          ? const Color(0xFF4CAF50)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),

              Text(step.emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                step.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                step.description,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isIntro ? _nextStep : _handleStep,
                  child: Text(
                    isIntro
                        ? 'Get Started'
                        : isLast
                            ? 'Done — Let\'s go! 🚀'
                            : 'Allow & Continue',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (!isIntro && !isLast) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _nextStep,
                  child: Text('Skip for now',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardStep {
  final String emoji;
  final String title;
  final String description;
  final Permission? permission;
  final bool isOverlay;

  const _OnboardStep({
    required this.emoji,
    required this.title,
    required this.description,
    this.permission,
    this.isOverlay = false,
  });
}

