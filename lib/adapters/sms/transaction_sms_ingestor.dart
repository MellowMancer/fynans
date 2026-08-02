import 'dart:convert';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';

/// Turns a bank-transaction SMS into a saved [Transaction].
class TransactionSmsIngestor {
  final SmsParserService _parser;
  final TransactionRepository _repository;

  TransactionSmsIngestor({required TransactionRepository repository})
      : _parser = SmsParserService(),
        _repository = repository;

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

    final t = Transaction()
      ..amount = details.amount
      ..date = details.date
      ..isCredit = isCredit
      ..party = party
      ..tags = <String>[]
      ..group = <String>[]
      ..note = _buildNote(sender, details)
      // De-dupe on raw SMS identity: keeps the launch sweep idempotent while
      // distinct SMS sharing minute+amount+party still import separately.
      ..smsId = smsIdFor(sender: sender, body: body, date: date)
      // Keep the original text so the UI can show what was parsed.
      ..smsBody = body;

    return _repository.importTransaction(t);
  }

  String _buildNote(String sender, ParsedTransactionDetails d) {
    final parts = <String>['Auto-imported from SMS · $sender'];
    if (d.accountNumber != null) parts.add('A/c x${d.accountNumber}');
    if (d.balance != null) parts.add('Bal ₹${d.balance!.toStringAsFixed(2)}');
    return parts.join(' · ');
  }
}

/// Deterministic identity of a raw SMS, derived purely from its content
/// (sender, body, timestamp) using FNV-1a.
const int kSmsIdLength = 16;

/// Whether [smsId] was produced by the current (FNV-1a) scheme.
bool isCurrentSmsIdFormat(String smsId) => _currentIdPattern.hasMatch(smsId);

/// Anchored and fixed-width, so it already enforces [kSmsIdLength].
final RegExp _currentIdPattern = RegExp('^[0-9a-f]{$kSmsIdLength}\$');

String smsIdFor({
  required String sender,
  required String body,
  required DateTime date,
}) {
  const int fnvOffsetBasis = 0xcbf29ce484222325;
  const int fnvPrime = 0x100000001b3;

  final payload = utf8.encode(
    '$sender\u0000$body\u0000${date.millisecondsSinceEpoch}',
  );

  var hash = fnvOffsetBasis;
  for (final byte in payload) {
    hash ^= byte;
    hash = hash * fnvPrime; // wraps at 64 bits
  }

  // Emit as two unsigned 32-bit halves so the text form is always positive.
  final high = (hash >> 32).toUnsigned(32).toRadixString(16).padLeft(8, '0');
  final low = hash.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  return '$high$low';
}
