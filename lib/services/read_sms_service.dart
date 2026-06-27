import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fynans/services/inbox_sms.dart';

/// Reads the SMS inbox (catch-up / dev TestSMS). Real-time monitoring lives in
/// [SmsIntakeService]; this is the on-demand inbox query.
class ReadSmsService {
  final Telephony _telephony = Telephony.instance;
  static const String _lastReadTimestampKey = 'last_read_timestamp';

  /// Fetch inbox messages newer than the last read timestamp. On first run,
  /// defaults to the last 7 days. Advances the timestamp after reading.
  Future<List<InboxSms>> getNewSms() async {
    final granted = await _telephony.requestSmsPermissions ?? false;
    if (!granted) return [];

    final prefs = await SharedPreferences.getInstance();
    final lastReadTimestamp = prefs.getInt(_lastReadTimestampKey);

    final DateTime lastReadDate = lastReadTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(lastReadTimestamp)
        : DateTime.now().subtract(const Duration(days: 7));

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
