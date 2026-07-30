import 'dart:convert';
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
    final smsId = smsIdFor(sender: sender, body: body, date: date);
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
      ..smsId = smsId
      // Keep the original text so the UI can show what was parsed.
      ..smsBody = body;

    await _repository.saveTransaction(t);
    return true;
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
///
/// This MUST NOT use `Object.hash`/`String.hashCode`: Dart seeds those per
/// process, so ids changed on every app launch, dedupe never matched and the
/// entire inbox was re-imported (and duplicated) each start. FNV-1a over the
/// UTF-8 bytes yields the same id in every process, on every device.
/// Width of a current-format id: two unsigned 32-bit halves in hex.
const int kSmsIdLength = 16;

/// Whether [smsId] was produced by the current (FNV-1a) scheme.
///
/// The previous scheme used `Object.hash(...).toUnsigned(32)`, which is seeded
/// per process and rendered without padding — at most 8 hex chars. Those ids
/// can never be recomputed, so records carrying them are unmatchable and must
/// be migrated rather than compared.
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
