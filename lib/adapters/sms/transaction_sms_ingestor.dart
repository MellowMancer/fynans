import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/data/hive_transaction_repository.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';

/// Turns a bank-transaction SMS into a saved [Transaction]. Used by both the
/// live listener (SmsIntakeService) and the launch catch-up scan, so it
/// de-dupes against the Hive box to avoid importing the same SMS twice.
class TransactionSmsIngestor {
  final SmsParserService _parser;
  final TransactionRepository _repository;

  /// [repository] defaults to the Hive-backed impl for production; tests inject
  /// a fake. Full constructor DI of the parser/source is the deferred F16.
  TransactionSmsIngestor({TransactionRepository? repository})
      : _parser = SmsParserService(),
        _repository = repository ?? HiveTransactionRepository();

  /// Returns true if a new transaction was saved.
  Future<bool> ingest({
    required String sender,
    required String body,
    required DateTime date,
  }) async {
    final details = _parser.parseTransactionDetails(
      sender: sender,
      body: body,
      date: date,
    );
    if (details == null) return false;
    // Only money-moving SMS become transactions.
    if (details.type != TransactionType.debit &&
        details.type != TransactionType.credit) {
      return false;
    }

    final isCredit = details.type == TransactionType.credit;
    final party = (details.merchant?.trim().isNotEmpty ?? false)
        ? details.merchant!.trim()
        : sender;

    // De-dupe on the RAW SMS identity so the full-inbox launch sweep stays
    // idempotent, while two genuinely distinct SMS that share
    // minute+amount+party are still imported separately (Bug #1 fix).
    final smsId = _smsId(sender: sender, body: body, date: date);
    if (_repository.existsWithSmsId(smsId)) {
      return false;
    }

    final t = Transaction()
      ..amount = details.amount
      ..date = details.date
      ..isCredit = isCredit
      ..party = party
      ..tags = <String>[]
      ..group = <String>[]
      ..note = _buildNote(sender, details)
      ..smsId = smsId;

    await _repository.saveTransaction(t);
    return true;
  }

  /// Deterministic identity of a raw SMS: hex of a stable hash over
  /// (sender, body, date). No randomness/wall-clock, so re-scans match.
  String _smsId({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final hash =
        Object.hash(sender, body, date.millisecondsSinceEpoch);
    return hash.toUnsigned(32).toRadixString(16);
  }

  String _buildNote(String sender, ParsedTransactionDetails d) {
    final parts = <String>['Auto-imported from SMS · $sender'];
    if (d.accountNumber != null) parts.add('A/c x${d.accountNumber}');
    if (d.balance != null) parts.add('Bal ₹${d.balance!.toStringAsFixed(2)}');
    return parts.join(' · ');
  }
}
