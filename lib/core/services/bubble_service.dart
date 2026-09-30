import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BubbleOverlay
// Entry-point class invoked by flutter_overlay_window in a separate isolate.
// ─────────────────────────────────────────────────────────────────────────────

class BubbleOverlay {
  /// Called from main.dart as the overlay entry point.
  static void startOverlayEntry() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _BubbleWidget(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BubbleWidget — the actual floating circle UI
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleWidget extends StatefulWidget {
  const _BubbleWidget();

  @override
  State<_BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<_BubbleWidget>
    with SingleTickerProviderStateMixin {
  int _splitId = -1;
  double _amount = 0;
  String _merchant = '';
  int _pendingCount = 1;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  Timer? _autoHideTimer;
  static const _autoHideDuration = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          _splitId = data['split_id'] ?? -1;
          _amount = (data['amount'] ?? 0).toDouble();
          _merchant = data['merchant'] ?? '';
          _pendingCount = data['pending_count'] ?? 1;
        });
        _resetTimer();
      }
    });

    _resetTimer();
  }

  void _resetTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideDuration, _onAutoHide);
  }

  Future<void> _onAutoHide() async {
    if (_splitId > 0) {
      await NotificationService.instance.showAutoSavedNotification(
        splitId: _splitId,
        amount: _amount,
        merchant: _merchant,
      );
    }
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onTap,
        child: ScaleTransition(
          scale: _pulseAnim,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '₹',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_pendingCount > 1)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_pendingCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap() {
    FlutterOverlayWindow.shareData({
      'action': 'open_split',
      'split_id': _splitId,
      'amount': _amount,
      'merchant': _merchant,
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BubbleService — called from main app to show/hide/update the bubble
// ─────────────────────────────────────────────────────────────────────────────

class BubbleService {
  static Future<bool> get hasPermission async =>
      FlutterOverlayWindow.isPermissionGranted();

  static Future<void> requestPermission() =>
      FlutterOverlayWindow.requestPermission();

  static Future<void> show({
    required int splitId,
    required double amount,
    required String merchant,
    int pendingCount = 1,
  }) async {
    if (!await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'SplitSnap',
        overlayContent: 'Payment detected',
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.bottomRight,
        positionGravity: PositionGravity.auto,
        width: 72,
        height: 72,
      );
    }
    await FlutterOverlayWindow.shareData({
      'split_id': splitId,
      'amount': amount,
      'merchant': merchant,
      'pending_count': pendingCount,
    });
  }

  static Future<void> dismiss() async {
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  static Stream<Map<String, dynamic>> get onBubbleTapped =>
      FlutterOverlayWindow.overlayListener
          .where((d) => d is Map && d['action'] == 'open_split')
          .cast<Map<String, dynamic>>();
}

