import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _autoSaveChannelId = 'splitsnap_autosave';
  static const _autoSaveChannelName = 'Auto-saved splits';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
  }

  /// Show silent notification after bubble auto-disappears
  Future<void> showAutoSavedNotification({
    required int splitId,
    required double amount,
    required String merchant,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _autoSaveChannelId,
        _autoSaveChannelName,
        channelDescription: 'Notifications for auto-saved incomplete splits',
        importance: Importance.low,
        priority: Priority.low,
        silent: true,
        styleInformation: BigTextStyleInformation(
          '₹${amount.toStringAsFixed(0)} from $merchant was auto-saved. Tap to add people & note.',
        ),
      ),
    );
    await _plugin.show(
      splitId,
      '💾 Payment saved — add details when free',
      '₹${amount.toStringAsFixed(0)} · $merchant',
      details,
      payload: 'split:$splitId',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}
