import 'package:fynans/adapters/sms/inbox_sms.dart';
import 'package:fynans/adapters/sms/read_sms_service.dart';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// SMS intake for the transaction pipeline: reads the inbox and turns bank
/// transaction SMS into saved [Transaction]s.
class SmsIntakeService {
  /// One-shot inbox sweep run on every launch (and, for immediacy, right
  /// after a card is added).
  ///
  /// Takes the repositories rather than reaching for one: the ingestor used
  /// to default to a concrete implementation, which is the kind of hidden
  /// construction that makes the storage layer hard to swap.
  ///
  /// [onProgress], when given, is called after each message is processed
  /// with (messages scanned so far, total messages) — lets a caller like
  /// [AddCardCubit] drive a real progress indicator instead of a bare spinner.
  static Future<int> catchUp(
    TransactionRepository repository,
    CardRepository cardRepository,
    DetectedCardRepository detectedCardRepository,
    CardStatementRepository statementRepository, {
    void Function(int scanned, int total)? onProgress,
  }) async {
    final ingestor = TransactionSmsIngestor(
      repository: repository,
      cardRepository: cardRepository,
      detectedCardRepository: detectedCardRepository,
      statementRepository: statementRepository,
    );
    final List<InboxSms> messages = await ReadSmsService().getAllSms();
    var imported = 0;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final saved = await ingestor.ingest(
        sender: m.sender,
        body: m.body,
        date: m.date,
      );
      if (saved) imported++;
      onProgress?.call(i + 1, messages.length);
    }
    return imported;
  }
}
