import 'package:another_telephony/telephony.dart';
import 'detector.dart';
import 'notifications.dart';
import 'storage.dart';

/// Tier C — reads/listens for incoming SMS and scans them on-device.
/// NOTE: Google Play heavily restricts READ_SMS/RECEIVE_SMS. This is built
/// for the sideloaded-APK proof-of-concept; Play distribution would need a
/// permissions declaration (or shipping as the default SMS handler).

/// Background isolate entry point. Must be top-level + vm:entry-point so the
/// platform can invoke it when the app is killed.
@pragma('vm:entry-point')
void onBackgroundSms(SmsMessage message) async {
  final body = message.body ?? '';
  if (body.trim().isEmpty) return;
  final result = analyze(body);
  if (result.verdict.level == 'low') return;
  await Notifications.alertScam(result, from: message.address);
  await Store.pushHistory(HistoryItem.fromResult(result, 'sms'));
}

class SmsService {
  static final Telephony _telephony = Telephony.instance;

  /// Request SMS permissions and begin listening. Returns true if granted.
  static Future<bool> enable({void Function(AnalysisResult, String? from)? onForeground}) async {
    final granted = await _telephony.requestPhoneAndSmsPermissions ?? false;
    if (!granted) return false;
    await Notifications.init();
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? '';
        if (body.trim().isEmpty) return;
        final result = analyze(body);
        await Store.pushHistory(HistoryItem.fromResult(result, 'sms'));
        if (result.verdict.level != 'low') {
          await Notifications.alertScam(result, from: message.address);
        }
        onForeground?.call(result, message.address);
      },
      onBackgroundMessage: onBackgroundSms,
      listenInBackground: true,
    );
    return true;
  }

  /// Scan the most recent inbox messages on demand (e.g. first enable).
  static Future<List<AnalysisResult>> scanRecentInbox({int limit = 20}) async {
    final granted = await _telephony.requestSmsPermissions ?? false;
    if (!granted) return [];
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
    final out = <AnalysisResult>[];
    for (final m in messages.take(limit)) {
      final body = m.body ?? '';
      if (body.trim().isEmpty) continue;
      out.add(analyze(body));
    }
    return out;
  }
}
