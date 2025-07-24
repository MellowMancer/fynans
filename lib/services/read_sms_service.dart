import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadSmsService {
  final SmsQuery _smsQuery = SmsQuery();
  static const String _lastReadTimestampKey = 'last_read_timestamp';

  Future<List<SmsMessage>> getNewSms() async {
    var permission = await Permission.sms.status;
    if (!permission.isGranted) {
      permission = await Permission.sms.request();
      if (!permission.isGranted) {
        // Handle the case where the user denies permission.
        return [];
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final lastReadTimestamp = prefs.getInt(_lastReadTimestampKey);

    DateTime? lastReadDate;
    if (lastReadTimestamp != null) {
      lastReadDate = DateTime.fromMillisecondsSinceEpoch(lastReadTimestamp);
    } else {
      lastReadDate = DateTime.now().subtract(const Duration(days: 7));
    }

    // The package doesn't support filtering by date directly in the query.
    // We fetch a recent batch of messages and then filter them in Dart.
    // The package sorts messages by date descending by default, so fetching
    // the last 200 should be sufficient for most use cases.
    final allMessages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 200,
    );

    final newMessages = allMessages.where((SmsMessage message) {
      // Filter messages that are newer than the last read date.
      return message.date != null && message.date!.isAfter(lastReadDate!);
    }).toList();

    await prefs.setInt(_lastReadTimestampKey, DateTime.now().millisecondsSinceEpoch);
    return newMessages;
  }
}