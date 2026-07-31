import 'package:another_telephony/telephony.dart';
import 'package:fynans/adapters/sms/inbox_sms.dart';

/// Reads the SMS inbox (catch-up / dev TestSMS).
class ReadSmsService {
  final Telephony _telephony = Telephony.instance;

  /// Read the inbox and return every message, newest first.
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
}
