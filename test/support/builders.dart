import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/new_transaction_kind.dart';

/// Shared test data builders.
///
/// Each builder sets every required field, so a test names only the fields
/// that matter to it. A new required field on an entity changes this file,
/// not every test. Dates are fixed, never `DateTime.now()`, so the tests stay
/// deterministic: a test that needs "this month" passes the date itself.

/// The date of a transaction when the test gives none.
final defaultTransactionDate = DateTime(2026, 7, 15);

/// The closing date of a closed card when the test gives none.
final defaultClosedOn = DateTime(2026, 7, 31);

/// The date of a statement when the test gives none.
final defaultStatementDate = DateTime(2026, 1, 15);

/// The date of a sighting when the test gives none.
final defaultSeenAt = DateTime(2026, 1, 1);

/// The credit limit of a credit card when the test gives none.
const defaultCreditLimit = 50000.0;

/// A transaction. Without a [kind], it takes the kind that the app gives a
/// new row: from [isInflow] and the [card] (a credit card spend is debt).
/// A [card] also sets [cardId], unless [cardId] is given.
Transaction aTransaction({
  int? id,
  double amount = 100,
  DateTime? date,
  bool isInflow = false,
  TransactionKind? kind,
  PaymentCard? card,
  int? cardId,
  String party = 'Merchant',
  List<String> tags = const [],
  List<String> group = const [],
  String? note,
  String? smsId,
  String? smsBody,
  double? cardAvailableLimit,
}) =>
    Transaction()
      ..id = id
      ..amount = amount
      ..date = date ?? defaultTransactionDate
      ..isInflow = isInflow
      ..kind = kind ?? newTransactionKind(isInflow: isInflow, card: card)
      ..cardId = cardId ?? card?.id
      ..party = party
      // Growable copies, so that a test or the code under test can change
      // them.
      ..tags = List.of(tags)
      ..group = List.of(group)
      ..note = note
      ..smsId = smsId
      ..smsBody = smsBody
      ..cardAvailableLimit = cardAvailableLimit;

/// A card, active unless [status] says otherwise. A credit card gets
/// [defaultCreditLimit] and a debit card no limit, unless [creditLimit] is
/// given. A closed card gets [defaultClosedOn] unless [closedOn] is given.
PaymentCard aCard({
  int? id,
  CardType type = CardType.credit,
  CardStatus status = CardStatus.active,
  String issuer = 'HDFC',
  String last4 = '1234',
  double? creditLimit,
  String? accountLast4,
  DateTime? closedOn,
  String? nickname,
}) =>
    PaymentCard()
      ..id = id
      ..type = type
      ..status = status
      ..issuer = issuer
      ..last4 = last4
      ..creditLimit = creditLimit ??
          (type == CardType.credit ? defaultCreditLimit : null)
      ..accountLast4 = accountLast4
      ..closedOn = closedOn ??
          (status == CardStatus.closed ? defaultClosedOn : null)
      ..nickname = nickname;

/// A card statement for [cardId], or for [card], or for card 1. A [card]
/// must be saved first: its id is null until then, and a statement for no
/// card is a mistake in the test, not a default.
CardStatement aStatement({
  int? id,
  PaymentCard? card,
  int? cardId,
  DateTime? statementDate,
  DateTime? dueDate,
  double? totalDue,
  double? minimumDue,
  String? smsId,
  String? smsBody,
}) =>
    CardStatement()
      ..id = id
      ..cardId = cardId ?? (card == null ? 1 : card.id!)
      ..statementDate = statementDate ?? defaultStatementDate
      ..dueDate = dueDate
      ..totalDue = totalDue
      ..minimumDue = minimumDue
      ..smsId = smsId
      ..smsBody = smsBody;

/// A card seen in SMS but not registered, first and last seen at [seenAt].
DetectedCard aSighting({
  String issuerGuess = 'HDFC',
  String sender = 'HDFCCC',
  String last4 = '1234',
  DateTime? seenAt,
  bool dismissed = false,
}) =>
    DetectedCard()
      ..issuerGuess = issuerGuess
      ..sender = sender
      ..last4 = last4
      ..firstSeen = seenAt ?? defaultSeenAt
      ..lastSeen = seenAt ?? defaultSeenAt
      ..dismissed = dismissed;
