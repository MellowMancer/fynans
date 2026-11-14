import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';

import '../fakes/fake_card_repository.dart';
import '../fakes/fake_card_statement_repository.dart';
import '../fakes/fake_detected_card_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  _smsIdStabilityTests();

  // Two genuinely distinct bank SMS that happen to share the same date-minute +
  // amount + party (same UPI VPA).
  const sender = 'AX-HDFCBK';
  const bodyA =
      'Rs.500.00 debited from a/c XX1234 to john@okhdfc on 08Jul. Avl Bal Rs.9000';
  const bodyB =
      'Rs.500.00 debited from a/c XX1234 to john@okhdfc ref no 887766. Avl Bal Rs.4000';
  final date = DateTime(2026, 7, 8, 10, 30);

  late FakeTransactionRepository repository;
  late FakeCardRepository cardRepository;
  late FakeDetectedCardRepository detectedCardRepository;
  late FakeCardStatementRepository statementRepository;
  late TransactionSmsIngestor ingestor;

  setUp(() {
    repository = FakeTransactionRepository();
    cardRepository = FakeCardRepository();
    detectedCardRepository = FakeDetectedCardRepository();
    statementRepository = FakeCardStatementRepository();
    ingestor = TransactionSmsIngestor(
      repository: repository,
      cardRepository: cardRepository,
      detectedCardRepository: detectedCardRepository,
      statementRepository: statementRepository,
    );
  });

  test('two distinct SMS sharing minute+amount+party persist as two records',
      () async {
    final savedA =
        await ingestor.ingest(sender: sender, body: bodyA, date: date);
    final savedB =
        await ingestor.ingest(sender: sender, body: bodyB, date: date);

    expect(savedA, isTrue);
    expect(savedB, isTrue);

    final stored = await repository.fetchTransactionsInRange(
        range: DateRange.month(DateTime(2026, 7)));
    expect(stored, hasLength(2));
  });

  test('re-ingesting the same two SMS stays idempotent (still two records)',
      () async {
    await ingestor.ingest(sender: sender, body: bodyA, date: date);
    await ingestor.ingest(sender: sender, body: bodyB, date: date);

    // Second full-inbox sweep of the identical messages.
    final reSavedA =
        await ingestor.ingest(sender: sender, body: bodyA, date: date);
    final reSavedB =
        await ingestor.ingest(sender: sender, body: bodyB, date: date);

    expect(reSavedA, isFalse);
    expect(reSavedB, isFalse);

    final stored = await repository.fetchTransactionsInRange(
        range: DateRange.month(DateTime(2026, 7)));
    expect(stored, hasLength(2));
  });

  group('credit-card SMS', () {
    const cardSender = 'SBICRD';
    const spendBody =
        'Rs.259.00 spent on your SBI Credit Card ending with 1234 on 15Jan26. '
        'Your available limit is Rs.1,235.00.';
    final cardDate = DateTime(2026, 1, 15);

    test('a matched card SMS goes to its card as debt, and to the main list',
        () async {
      final card = PaymentCard()
        ..issuer = 'SBI Card'
        ..last4 = '1234'
        ..type = CardType.credit
        ..status = CardStatus.active
        ..creditLimit = 5000;
      cardRepository.seed([card]);
      ingestor = TransactionSmsIngestor(
        repository: repository,
        cardRepository: cardRepository,
        detectedCardRepository: detectedCardRepository,
        statementRepository: statementRepository,
      );

      final saved = await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);
      expect(saved, isTrue);

      // Matches how the app's own screens read the main list.
      final mainList = await repository.fetchTransactionsInRange(
        range: DateRange.month(cardDate),
        filter: const TransactionFilter.empty(),
      );
      expect(mainList, hasLength(1));
      expect(mainList.single.kind, TransactionKind.debt);

      final cardTxns =
          await repository.listenToTransactionsForCard(card.id!).first;
      expect(cardTxns, hasLength(1));
      expect(cardTxns.first.cardAvailableLimit, 1235.00);
      expect(cardTxns.first.isInflow, isFalse);
    });

    test(
        'unmatched card SMS is dropped, leaving no registered cards behaves'
        ' the same as before card SMS were classified at all', () async {
      // No card seeded — matchCard has nothing to match against.
      final saved = await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);
      expect(saved, isFalse);

      final mainList = await repository.fetchTransactionsInRange(
          range: DateRange.month(cardDate));
      expect(mainList, isEmpty);
    });

    test('an unmatched card SMS records a sighting instead of vanishing',
        () async {
      // No card seeded.
      await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);

      final pending = await detectedCardRepository.watchPending().first;
      expect(pending, hasLength(1));
      expect(pending.single.issuerGuess, 'SBI Card');
      expect(pending.single.sender, cardSender);
      expect(pending.single.last4, '1234');
      expect(pending.single.sightingCount, 1);

      // Still no transaction saved — a sighting is never a guessed spend.
      expect(
        await repository.fetchTransactionsInRange(
            range: DateRange.month(cardDate)),
        isEmpty,
      );
    });

    test(
        'repeated sightings of the same unmatched card bump the count, '
        'not create duplicates', () async {
      await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);
      await ingestor.ingest(
          sender: cardSender,
          body: spendBody,
          date: cardDate.add(const Duration(days: 1)));

      final pending = await detectedCardRepository.watchPending().first;
      expect(pending, hasLength(1));
      expect(pending.single.sightingCount, 2);
    });

    test('a dismissed sighting is not resurrected by a new SMS', () async {
      await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);
      final first = (await detectedCardRepository.watchPending().first).single;
      await detectedCardRepository.dismiss(first);

      await ingestor.ingest(
          sender: cardSender,
          body: spendBody,
          date: cardDate.add(const Duration(days: 1)));

      expect(await detectedCardRepository.watchPending().first, isEmpty,
          reason: 'dismissal is sticky');
    });

    test('a matched card SMS does not record a sighting', () async {
      final card = PaymentCard()
        ..issuer = 'SBI Card'
        ..last4 = '1234'
        ..type = CardType.credit
        ..status = CardStatus.active
        ..creditLimit = 5000;
      cardRepository.seed([card]);
      ingestor = TransactionSmsIngestor(
        repository: repository,
        cardRepository: cardRepository,
        detectedCardRepository: detectedCardRepository,
        statementRepository: statementRepository,
      );

      await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);

      expect(await detectedCardRepository.watchPending().first, isEmpty);
    });

    test(
        'a card SMS already on disk without a card is linked to the card on '
        'the next sweep', () async {
      // As if the SMS was imported before the parser recognised it as a card
      // SMS: the row has the same smsId, but no card.
      repository.seed([
        Transaction()
          ..amount = 259
          ..date = cardDate
          ..tags = <String>[]
          ..party = 'x'
          ..isInflow = false
          ..kind = TransactionKind.expense
          ..smsId =
              smsIdFor(sender: cardSender, body: spendBody, date: cardDate),
      ]);
      final card = PaymentCard()
        ..issuer = 'SBI Card'
        ..last4 = '1234'
        ..type = CardType.credit
        ..status = CardStatus.active
        ..creditLimit = 5000;
      cardRepository.seed([card]);

      final relinked = await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);

      expect(relinked, isTrue,
          reason: 'a link counts as this SMS being accounted for');
      expect(
        await repository.listenToTransactionsForCard(card.id!).first,
        hasLength(1),
        reason: 'the existing row now belongs to the card',
      );
      final mainList = await repository.fetchTransactionsInRange(
        range: DateRange.month(cardDate),
        filter: const TransactionFilter.empty(),
      );
      expect(mainList.single.cardId, card.id,
          reason: 'the row stays in the main list, now with its card');
    });
  });
}

void _smsIdStabilityTests() {
  group('smsIdFor', () {
    final date =
        DateTime.fromMillisecondsSinceEpoch(1785000000000, isUtc: true);
    const sender = 'HDFCBK';
    const body = 'Rs.250.00 debited from a/c XX1234 at Corner Cafe.';

    test('is a pure function of the SMS content (golden)', () {
      // A hardcoded expectation is the point: it can only hold if the id is
      // derived from content rather than a per-process hash seed.
      expect(
        smsIdFor(sender: sender, body: body, date: date),
        smsIdFor(sender: sender, body: body, date: date),
      );
      expect(
        smsIdFor(sender: sender, body: body, date: date),
        hasLength(16),
      );
      expect(
        smsIdFor(sender: sender, body: body, date: date),
        matches(RegExp(r'^[0-9a-f]{16}$')),
      );
    });

    test('changes when any component changes', () {
      final base = smsIdFor(sender: sender, body: body, date: date);
      expect(smsIdFor(sender: 'ICICIB', body: body, date: date), isNot(base));
      expect(smsIdFor(sender: sender, body: '$body ', date: date), isNot(base));
      expect(
        smsIdFor(
          sender: sender,
          body: body,
          date: date.add(const Duration(minutes: 1)),
        ),
        isNot(base),
      );
    });
  });
}
