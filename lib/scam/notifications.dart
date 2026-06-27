import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'detector.dart';

/// Local scam alerts — replaces the service-worker showNotification().
class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'finshield_alerts',
    'Scam alerts',
    description: 'Warns you when an incoming message looks like a scam.',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    await init();
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Fire an alert for a medium/high verdict.
  static Future<void> alertScam(AnalysisResult r, {String? from}) async {
    if (r.verdict.level == 'low') return;
    await init();
    final body = [
      if (from != null) 'From $from',
      r.findings.where((f) => f.points > 0).take(2).map((f) => f.title).join(' · '),
    ].where((s) => s.isNotEmpty).join('\n');
    await _plugin.show(
      r.text.hashCode & 0x7fffffff,
      '⚠ ${r.verdict.label} — risk ${r.score}/100',
      body.isEmpty ? r.verdict.blurb : body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body.isEmpty ? r.verdict.blurb : body),
        ),
      ),
    );
  }

  static Future<void> test() async {
    await init();
    await _plugin.show(
      0,
      '⚠ Likely scam — risk 86/100',
      'This is how FinShield warns you about a risky message.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'finshield_alerts',
          'Scam alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
