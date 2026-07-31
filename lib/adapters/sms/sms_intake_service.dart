import 'package:fynans/adapters/sms/inbox_sms.dart';
import 'package:fynans/adapters/sms/read_sms_service.dart';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';

/// SMS intake for the transaction pipeline: reads the inbox and turns bank
/// transaction SMS into saved [Transaction]s.
class SmsIntakeService {
  static final TransactionSmsIngestor _ingestor = TransactionSmsIngestor();

  /// One-shot inbox sweep run on every launch.
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
