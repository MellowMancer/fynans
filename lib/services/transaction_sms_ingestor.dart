import 'package:fynans/models/transaction.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:fynans/services/parsed_transaction.dart';
import 'package:fynans/services/sms_parser_service.dart';

/// Turns a bank-transaction SMS into a saved [Transaction]. Used by both the
/// live listener (SmsIntakeService) and the launch catch-up scan, so it
/// de-dupes against the Hive box to avoid importing the same SMS twice.
class TransactionSmsIngestor {
  final SmsParserService _parser = SmsParserService();
  final HiveService _hive = HiveService();

  /// Returns true if a new transaction was saved.
  /// [scamScore] (0–100) is the FinShield risk score for the same SMS; stored
  /// on the transaction when it's suspicious (≥25) so the UI can flag it.
  Future<bool> ingest({
    required String sender,
    required String body,
    required DateTime date,
    int? scamScore,
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

    // De-dupe against the box itself so the full-inbox launch sweep stays
    // idempotent (and a cleared database correctly re-imports).
    if (_hive.hasMatchingTransaction(
      date: details.date,
      amount: details.amount,
      isCredit: isCredit,
      party: party,
    )) {
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
      ..scamScore = (scamScore != null && scamScore >= 25) ? scamScore : null;

    await _hive.saveTransaction(t);
    return true;
  }

  String _buildNote(String sender, ParsedTransactionDetails d) {
    final parts = <String>['Auto-imported from SMS · $sender'];
    if (d.accountNumber != null) parts.add('A/c x${d.accountNumber}');
    if (d.balance != null) parts.add('Bal ₹${d.balance!.toStringAsFixed(2)}');
    return parts.join(' · ');
  }
}
