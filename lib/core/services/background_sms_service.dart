import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:telephony/telephony.dart';
import '../utils/upi_parser.dart';
import '../database/app_database.dart';
import '../services/context_capture_service.dart';
import '../services/notification_service.dart';
import '../../models/split.dart';

/// Called by the background service isolate — must be a top-level function.
@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'SplitSnap',
      content: 'Watching for UPI payments…',
    );
  }

  await NotificationService.instance.init();

  final telephony = Telephony.instance;

  // Listen for incoming SMS in background
  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) async {
      final body = message.body ?? '';
      final sender = message.address ?? '';
      final payment = UpiParser.parse(body, sender);
      if (payment == null) return;

      // 1. Save immediately as Incomplete
      final split = Split(
        amount: payment.amount,
        merchant: payment.merchant,
        bankName: payment.bankName,
        upiRef: payment.upiRef,
        isComplete: false,
        createdAt: payment.detectedAt,
      );
      final splitId = await AppDatabase.instance.insertSplit(split);

      // 2. Notify main isolate to show bubble
      service.invoke('show_bubble', {
        'split_id': splitId,
        'amount': payment.amount,
        'merchant': payment.merchant,
      });

      // 3. Capture context silently in background (non-blocking)
      _captureContextForSplit(splitId, payment.amount, payment.merchant);
    },
    listenInBackground: true,
  );

  // Keep service alive
  Timer.periodic(const Duration(minutes: 5), (_) {
    service.invoke('ping', {});
  });
}

Future<void> _captureContextForSplit(
    int splitId, double amount, String merchant) async {
  try {
    final ctx = await ContextCaptureService.instance.capture(
      maxRetries: 3,
      retryDelay: const Duration(seconds: 30),
    );
    await AppDatabase.instance.updateSplitContext(
      id: splitId,
      latitude: ctx.latitude,
      longitude: ctx.longitude,
      locationName: ctx.locationName,
      wifiName: ctx.wifiName,
    );
  } catch (_) {}
}

class BackgroundSmsService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'splitsnap_bg',
        initialNotificationTitle: 'SplitSnap',
        initialNotificationContent: 'Watching for UPI payments…',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
    await service.startService();
  }

  static Future<void> startListening({
    required Function(Map<String, dynamic>) onPaymentDetected,
  }) async {
    final service = FlutterBackgroundService();
    service.on('show_bubble').listen((data) {
      if (data != null) onPaymentDetected(data);
    });
  }
}
