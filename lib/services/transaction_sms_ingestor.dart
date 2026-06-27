import 'package:shared_preferences/shared_preferences.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:fynans/services/parsed_transaction.dart';
import 'package:fynans/services/sms_parser_service.dart';

/// Turns a bank-transaction SMS into a saved [Transaction]. Used by both the
/// live listener (SmsIntakeService) and the launch catch-up scan, so it
/// de-dupes by message content to avoid importing the same SMS twice.
class TransactionSmsIngestor {
  final SmsParserService _parser = SmsParserService();
  final HiveService _hive = HiveService();

  static const _sigKey = 'sms_ingested_signatures';
  static const _sigCap = 300;

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

    final prefs = await SharedPreferences.getInstance();
    final sig = _signature(sender, body);
    final seen = prefs.getStringList(_sigKey) ?? <String>[];
    if (seen.contains(sig)) return false;

    final t = Transaction()
      ..amount = details.amount
      ..date = details.date
      ..isCredit = details.type == TransactionType.credit
      ..party = (details.merchant?.trim().isNotEmpty ?? false)
          ? details.merchant!.trim()
          : sender
      ..tags = <String>[]
      ..group = <String>[]
      ..note = _buildNote(sender, details)
      ..scamScore = (scamScore != null && scamScore >= 25) ? scamScore : null;

    await _hive.saveTransaction(t);

    seen.add(sig);
    if (seen.length > _sigCap) {
      seen.removeRange(0, seen.length - _sigCap);
    }
    await prefs.setStringList(_sigKey, seen);
    return true;
  }

  String _signature(String sender, String body) =>
      '${sender.trim()}|${body.trim().hashCode}';

  String _buildNote(String sender, ParsedTransactionDetails d) {
    final parts = <String>['Auto-imported from SMS · $sender'];
    if (d.accountNumber != null) parts.add('A/c x${d.accountNumber}');
    if (d.balance != null) parts.add('Bal ₹${d.balance!.toStringAsFixed(2)}');
    return parts.join(' · ');
  }
}
