import 'package:fynans/services/inbox_sms.dart';
import 'package:fynans/services/read_sms_service.dart';
import 'package:fynans/services/transaction_sms_ingestor.dart';

/// SMS intake for the transaction pipeline: reads the inbox and turns bank
/// transaction SMS into saved [Transaction]s. Importing bank SMS is the app's
/// core purpose, so this runs on every launch.
class SmsIntakeService {
  static final TransactionSmsIngestor _ingestor = TransactionSmsIngestor();

  /// One-shot inbox sweep run on every launch. Scans the FULL inbox (not just
  /// messages since a cursor) so the dashboard always reflects every parsable
  /// bank transaction — exactly what the TestSMS diagnostic shows. The ingestor
  /// de-dupes against Hive, so re-scanning every launch never creates
  /// duplicates and a cleared database correctly re-imports.
  /// Returns the number of new transactions imported.
  static Future<int> catchUp() async {
    final List<InboxSms> messages = await ReadSmsService().getAllSms();
    var imported = 0;
    for (final m in messages) {
      final saved = await _ingestor.ingest(
        sender: m.sender,
        body: m.body,
        date: m.date,
      );
      if (saved) imported++;
    }
    return imported;
  }
}
