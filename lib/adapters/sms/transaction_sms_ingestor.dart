import 'dart:convert';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';
import 'package:fynans/use_cases/guess_card_issuer.dart';
import 'package:fynans/use_cases/match_transaction_to_card.dart';

/// Turns a bank-transaction SMS into a saved [Transaction], or a card
/// statement SMS into a saved [CardStatement] — never both for the same SMS.
class TransactionSmsIngestor {
  final SmsParserService _parser;
  final TransactionRepository _repository;
  final CardRepository _cardRepository;
  final DetectedCardRepository _detectedCardRepository;
  final CardStatementRepository _statementRepository;

  /// Fetched once and reused for this instance's lifetime, not per [ingest]
  /// call — `SmsIntakeService.catchUp` creates one ingestor and calls
  /// [ingest] up to 1000 times per launch sweep.
  Future<List<CreditCard>>? _cardsFuture;

  TransactionSmsIngestor({
    required TransactionRepository repository,
    required CardRepository cardRepository,
    required DetectedCardRepository detectedCardRepository,
    required CardStatementRepository statementRepository,
  })  : _parser = SmsParserService(),
        _repository = repository,
        _cardRepository = cardRepository,
        _detectedCardRepository = detectedCardRepository,
        _statementRepository = statementRepository;

  Future<List<CreditCard>> _cards() =>
      _cardsFuture ??= _cardRepository.fetchCards();

  /// Returns true if a new transaction was saved. A recognized statement SMS
  /// returns false too — it saves a [CardStatement], never a [Transaction] —
  /// so callers counting "transactions imported" (`SmsIntakeService.catchUp`)
  /// don't have to distinguish the two.
  Future<bool> ingest({
    required String sender,
    required String body,
    required DateTime date,
  }) async {
    final statement = _parser.parseCardStatement(
      sender: sender,
      body: body,
      date: date,
    );
    if (statement != null) {
      final card = matchCard(
        await _cards(),
        last4: statement.cardLast4,
        sender: sender,
      );
      if (card?.id != null) {
        final smsId = smsIdFor(sender: sender, body: body, date: date);
        await _statementRepository.importStatement(CardStatement()
          ..cardId = card!.id!
          ..statementDate = statement.statementDate
          ..dueDate = statement.dueDate
          ..totalDue = statement.totalDue
          ..minimumDue = statement.minimumDue
          ..smsId = smsId
          ..smsBody = body);
      }
      // Unmatched → drop, same as an unmatched card transaction, minus the
      // detected-card sighting: a statement alone (no spend yet) is a
      // thinner signal that the card is actually the user's.
      return false;
    }

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

    int? cardId;
    double? cardAvailableLimit;
    if (details.isCreditCard) {
      final card = matchCard(
        await _cards(),
        last4: details.cardLast4,
        sender: sender,
      );
      // Unmatched → still no transaction is saved (never guess-attribute
      // real money to a card), but record a sighting so the user can be
      // prompted to register it, instead of the SMS silently vanishing.
      if (card == null) {
        final last4 = details.cardLast4;
        if (last4 != null) {
          await _detectedCardRepository.recordSighting(
            sender: sender,
            issuerGuess: guessCardIssuer(sender),
            last4: last4,
            seenAt: date,
          );
        }
        return false;
      }
      cardId = card.id;
      cardAvailableLimit = details.availableLimit;
    }

    final isCredit = details.type == TransactionType.credit;
    final party = (details.merchant?.trim().isNotEmpty ?? false)
        ? details.merchant!.trim()
        : sender;

    // De-dupe on raw SMS identity: keeps the launch sweep idempotent while
    // distinct SMS sharing minute+amount+party still import separately.
    final smsId = smsIdFor(sender: sender, body: body, date: date);

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
      ..smsBody = body
      ..cardId = cardId
      ..cardAvailableLimit = cardAvailableLimit;

    final imported = await _repository.importTransaction(t);
    if (imported) return true;

    // Already on disk under this smsId — the common case is just a repeat
    // scan (nothing to do). But if this is a matched card SMS, the existing
    // row might be one that got unlinked when its card was deleted and is
    // now sitting cardId-less in the main list; re-link it to the
    // newly-(re)registered card rather than leaving it stranded forever,
    // since importTransaction's insert-or-ignore has no way to do that itself.
    if (cardId != null) {
      return _repository.relinkTransactionToCard(
        smsId: smsId,
        cardId: cardId,
        cardAvailableLimit: cardAvailableLimit,
      );
    }
    return false;
  }

  String _buildNote(String sender, ParsedTransactionDetails d) {
    final parts = <String>['Auto-imported from SMS · $sender'];
    if (d.accountNumber != null) parts.add('A/c x${d.accountNumber}');
    if (d.balance != null) parts.add('Bal ₹${d.balance!.toStringAsFixed(2)}');
    return parts.join(' · ');
  }
}

/// Deterministic identity of a raw SMS, derived purely from its content

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
