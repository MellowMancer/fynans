import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fynans/services/inbox_sms.dart';

/// Reads the SMS inbox (catch-up / dev TestSMS). Real-time monitoring lives in
/// [SmsIntakeService]; this is the on-demand inbox query.
class ReadSmsService {
  final Telephony _telephony = Telephony.instance;
  static const String _lastReadTimestampKey = 'last_read_timestamp';

  /// Read the inbox and return every message, newest first. Does NOT advance
  /// any cursor, so it is safe to call repeatedly — used by the TestSMS
  /// diagnostic screen, which must show ALL parsable transactions on every
  /// refresh (not just messages received since the last read).
  ///
  /// [maxMessages] caps how many recent inbox rows are scanned as a perf guard.
  Future<List<InboxSms>> getAllSms({int maxMessages = 1000}) async {
    final granted = await _telephony.requestSmsPermissions ?? false;
    if (!granted) return [];

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final result = <InboxSms>[];
    for (final m in messages) {
      if (result.length >= maxMessages) break;
      final body = m.body;
      final address = m.address;
      if (body == null || address == null) continue;
      final date = m.date != null
          ? DateTime.fromMillisecondsSinceEpoch(m.date!)
          : DateTime.now();
      result.add(InboxSms(sender: address, body: body, date: date));
    }
    return result;
  }

  /// Fetch inbox messages newer than the last read timestamp, then advance the
  /// cursor. Consume-once: drives the launch catch-up ingest so we don't
  /// re-scan the whole inbox on every start. On first run the cursor is unset,
  /// so we import the ENTIRE inbox history (downstream de-dupe by signature
  /// keeps it idempotent) — that's how a fresh install lands every past
  /// transaction on the dashboard.
  Future<List<InboxSms>> getNewSms() async {
    final granted = await _telephony.requestSmsPermissions ?? false;
    if (!granted) return [];

    final prefs = await SharedPreferences.getInstance();
    final lastReadTimestamp = prefs.getInt(_lastReadTimestampKey);

    // No cursor yet (first run) => epoch, i.e. import all history.
    final DateTime lastReadDate = lastReadTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(lastReadTimestamp)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final newMessages = <InboxSms>[];
    for (final m in messages) {
      final body = m.body;
      final address = m.address;
      if (body == null || address == null) continue;
      final date = m.date != null
          ? DateTime.fromMillisecondsSinceEpoch(m.date!)
          : DateTime.now();
      if (date.isAfter(lastReadDate)) {
        newMessages.add(InboxSms(sender: address, body: body, date: date));
      }
    }

    await prefs.setInt(
        _lastReadTimestampKey, DateTime.now().millisecondsSinceEpoch);
    return newMessages;
  }
}
