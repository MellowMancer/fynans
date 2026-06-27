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

  // Quiet channel for "this SMS was checked and is safe" notifications, so
  // safe-message confirmations don't buzz like a scam alert does.
  static const _safeChannel = AndroidNotificationChannel(
    'finshield_checks',
    'SMS checks',
    description: 'Confirms an incoming message was scanned and looks safe.',
    importance: Importance.low,
  );

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final android7 = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android7?.createNotificationChannel(_channel);
    await android7?.createNotificationChannel(_safeChannel);
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

  /// Notify for ANY scanned SMS — safe, suspicious, or scam — so the user
  /// always gets a verdict. Risky verdicts use the high-importance alert
  /// channel; safe ones use the quiet checks channel.
  static Future<void> notifyResult(AnalysisResult r, {String? from}) async {
    await init();
    final level = r.verdict.level;
    final risky = level != 'low';
    final channel = risky ? _channel : _safeChannel;

    final title = level == 'high'
        ? '⚠ Likely scam — risk ${r.score}/100'
        : level == 'medium'
            ? '⚠ Suspicious — risk ${r.score}/100'
            : '✓ Looks safe — risk ${r.score}/100';

    final findings = r.findings
        .where((f) => f.points > 0)
        .take(2)
        .map((f) => f.title)
        .join(' · ');
    final body = [
      if (from != null) 'From $from',
      risky
          ? (findings.isEmpty ? r.verdict.blurb : findings)
          : 'No scam patterns found in this message.',
    ].where((s) => s.isNotEmpty).join('\n');

    await _plugin.show(
      r.text.hashCode & 0x7fffffff,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: risky ? Importance.high : Importance.low,
          priority: risky ? Priority.high : Priority.low,
          styleInformation: BigTextStyleInformation(body),
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
