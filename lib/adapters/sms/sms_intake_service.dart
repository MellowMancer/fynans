import 'dart:io' show Platform;

import 'package:fynans/adapters/sms/inbox_sms.dart';
import 'package:fynans/adapters/sms/read_sms_service.dart';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// SMS intake for the transaction pipeline: reads the inbox and turns bank
/// transaction SMS into saved [Transaction]s.
class SmsIntakeService {
  /// One-shot inbox sweep run on every launch.
  ///
  /// Takes the repository rather than reaching for one: the ingestor used to
  /// default to a concrete implementation, which is the kind of hidden
  /// construction that makes the storage layer hard to swap.
  static Future<int> catchUp(TransactionRepository repository) async {
    // Guard the pipeline itself, not just its callers: only Android lets an
    // app read the SMS inbox, and flutter_sms_inbox has no iOS
    // implementation, so calling it there throws at runtime.
    if (!Platform.isAndroid) return 0;

    final ingestor = TransactionSmsIngestor(repository: repository);
    final List<InboxSms> messages = await ReadSmsService().getAllSms();
    var imported = 0;
    for (final m in messages) {
      final saved = await ingestor.ingest(
        sender: m.sender,
        body: m.body,
        date: m.date,
      );
      if (saved) imported++;
    }
    return imported;
  }
}
