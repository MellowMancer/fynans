import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:fynans/adapters/sms/inbox_sms.dart';

/// Reads the SMS inbox (catch-up / dev TestSMS).
class ReadSmsService {
  final SmsQuery _smsQuery = SmsQuery();

  /// Static because callers hold their own [ReadSmsService]: the launch sweep
  /// builds one and the dev SMS screen another. Android rejects a second
  /// request while one is pending, so without this the two overlapping at
  /// startup throws rather than simply waiting.
  static Future<bool>? _pendingPermission;

  static Future<bool> _ensurePermission() {
    return _pendingPermission ??= _requestPermission()
        .whenComplete(() => _pendingPermission = null);
  }

  static Future<bool> _requestPermission() async {
    if ((await Permission.sms.status).isGranted) return true;
    return (await Permission.sms.request()).isGranted;
  }

  /// Read the inbox and return every message, newest first.
  Future<List<InboxSms>> getAllSms({int maxMessages = 1000}) async {
    if (!await _ensurePermission()) return [];

    // flutter_sms_inbox sorts inbox messages newest-first by default and has no
    // date filter, so we fetch the most recent [maxMessages] and map them onto
    // the package-neutral InboxSms record the rest of the app consumes.
    final messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      count: maxMessages,
    );

    final result = <InboxSms>[];
    for (final m in messages) {
      final body = m.body;
      final address = m.address;
      if (body == null || address == null) continue;
      result.add(InboxSms(
        sender: address,
        body: body,
        date: m.date ?? DateTime.now(),
      ));
    }
    return result;
  }
}
