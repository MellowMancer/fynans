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
  /// construction that makes the storage layer hard to swap. [smsInboxAvailable]
  /// follows the same rule: the caller (the composition root, which already
  /// computes this once) passes it in rather than this method re-deriving it
  /// from `Platform.isAndroid` itself -- that would be a hidden dependency
  /// with no test override, making this branch unreachable from a unit test.
  static Future<int> catchUp(
    TransactionRepository repository, {
    required bool smsInboxAvailable,
  }) async {
    // Only Android lets an app read the SMS inbox, and flutter_sms_inbox has
    // no iOS implementation, so reaching it there throws at runtime.
    if (!smsInboxAvailable) return 0;

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
