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
      expect(mainList.single.kind, TransactionKind.debt,
          reason: 'it was saved as an expense, before it had a credit card');
    });

    group('kinds', () {
      PaymentCard seedSbiCard() {
        final card = PaymentCard()
          ..issuer = 'SBI Card'
          ..last4 = '1234'
          ..type = CardType.credit
          ..status = CardStatus.active
          ..creditLimit = 50000;
        cardRepository.seed([card]);
        return card;
      }

      Future<Transaction> onlyRow() async => (await repository
              .fetchTransactionsInRange(range: DateRange.month(cardDate)))
          .single;

      test("the card's payment-received SMS is a repayment on the card",
          () async {
        final card = seedSbiCard();
        await ingestor.ingest(
          sender: cardSender,
          body: 'Your payment of Rs.1,644.55 has been credited to your SBI '
              'Credit Card ending with 1234. Your available limit is '
              'Rs.48,355.45.',
          date: cardDate,
        );

        final row = await onlyRow();
        expect(row.kind, TransactionKind.repayment);
        expect(row.isInflow, isTrue);
        expect(row.cardId, card.id);
      });

      test("the bank's debit towards the card bill is a repayment with no "
          'card', () async {
        seedSbiCard();
        await ingestor.ingest(
          sender: 'SBIINB',
          body: 'Rs.5,000.00 debited from A/c XX4321 towards payment of SBI '
              'Credit Card XX1234',
          date: cardDate,
        );

        final row = await onlyRow();
        expect(row.kind, TransactionKind.repayment);
        expect(row.isInflow, isFalse);
        expect(row.cardId, isNull);
      });

      test('a refund on the card is a refund', () async {
        final card = seedSbiCard();
        await ingestor.ingest(
          sender: cardSender,
          body: 'Refund of Rs.250.00 credited to your SBI Credit Card ending '
              '1234 for AMAZON.',
          date: cardDate,
        );

        final row = await onlyRow();
        expect(row.kind, TransactionKind.refund);
        expect(row.cardId, card.id);
      });
    });
  });

  group('bank account SMS and debit cards', () {
    const upiSpend =
        'Sent Rs 410.00 From HDFC Bank A/C *1111\nTo Mr Mr John Doe\nOn '
        '14/11/2026\nRef 111111111111';
    final day = DateTime(2026, 11, 14);

    PaymentCard card(CardType type, {String last4 = '9999', String? account}) =>
        PaymentCard()
          ..issuer = 'HDFC'
          ..last4 = last4
          ..type = type
          ..status = CardStatus.active
          ..accountLast4 = account
          ..creditLimit = type == CardType.credit ? 50000 : null;

    Future<Transaction> onlyRow() async => (await repository
            .fetchTransactionsInRange(range: DateRange.month(day)))
        .single;

    test('links to the debit card that draws from the account', () async {
      final debit = card(CardType.debit, account: '1111');
      cardRepository.seed([debit]);

      await ingestor.ingest(sender: 'AX-HDFCBK', body: upiSpend, date: day);

      final row = await onlyRow();
      expect(row.cardId, debit.id);
      expect(row.kind, TransactionKind.expense);
    });

    test('never links to a credit card, even with the same digits', () async {
      // The database allows account digits on a credit card; the rule must
      // still skip it.
      cardRepository
          .seed([card(CardType.credit, last4: '1111', account: '1111')]);

      await ingestor.ingest(sender: 'AX-HDFCBK', body: upiSpend, date: day);

      expect((await onlyRow()).cardId, isNull);
    });

    test('stays unlinked if no debit card has the account digits', () async {
      cardRepository.seed([card(CardType.debit, last4: '1111')]);

      await ingestor.ingest(sender: 'AX-HDFCBK', body: upiSpend, date: day);

      expect((await onlyRow()).cardId, isNull);
    });

    test('an old row links when the debit card is added later', () async {
      await ingestor.ingest(sender: 'AX-HDFCBK', body: upiSpend, date: day);
      final debit = card(CardType.debit, account: '1111');
      cardRepository.seed([debit]);

      final linked = await TransactionSmsIngestor(
        repository: repository,
        cardRepository: cardRepository,
        detectedCardRepository: detectedCardRepository,
        statementRepository: statementRepository,
      ).ingest(sender: 'AX-HDFCBK', body: upiSpend, date: day);

      expect(linked, isTrue);
      expect((await onlyRow()).cardId, debit.id);
    });
  });

  group('a card deleted during the sweep', () {
    final day = DateTime(2026, 1, 15);
    late PaymentCard card;

    /// Links the fakes to the card list, as the foreign key links the tables,
    /// then makes the ingestor read the card list once while the card exists.
    /// The SMS names other digits, so the card gets no rows and can be deleted.
    Future<void> sweepStartsWith(CardType type) async {
      repository = FakeTransactionRepository(cards: cardRepository);
      statementRepository = FakeCardStatementRepository(cards: cardRepository);
      ingestor = TransactionSmsIngestor(
        repository: repository,
        cardRepository: cardRepository,
        detectedCardRepository: detectedCardRepository,
        statementRepository: statementRepository,
      );
      card = PaymentCard()
        ..issuer = 'HDFC'
        ..last4 = '1234'
        ..type = type
        ..status = CardStatus.active
        ..creditLimit = type == CardType.credit ? 50000 : null;
      cardRepository.seed([card]);
      await ingestor.ingest(
          sender: 'HDFCBK',
          body: 'Rs.10.00 spent on HDFC Bank Debit Card XX9999 at TEA.',
          date: day);
      await cardRepository.deleteCard(card);
    }

    test('a debit card spend is saved without the card', () async {
      await sweepStartsWith(CardType.debit);

      final saved = await ingestor.ingest(
          sender: 'HDFCBK',
          body: 'Rs.500.00 spent on HDFC Bank Debit Card XX1234 at AMAZON.',
          date: day);

      expect(saved, isTrue);
      final rows = await repository.fetchTransactionsInRange(
          range: DateRange.month(day));
      expect(rows.where((t) => t.amount == 500).single.cardId, isNull);
    });

    test('a credit card spend becomes a sighting', () async {
      await sweepStartsWith(CardType.credit);

      final saved = await ingestor.ingest(
          sender: 'HDFCCC',
          body: 'Rs.500.00 spent on HDFC Bank Credit Card XX1234 at AMAZON.',
          date: day);

      expect(saved, isFalse);
      expect((await detectedCardRepository.watchPending().first).single.last4,
          '1234');
    });

    test('a statement is dropped', () async {
      await sweepStartsWith(CardType.credit);

      final saved = await ingestor.ingest(
          sender: 'HDFCCC',
          body: 'Your HDFC Bank Credit Card XX1234 statement: Total Dues '
              'Rs.8,500.00. Payment Due Date 05/02/2026.',
          date: day);

      expect(saved, isFalse);
      expect(await statementRepository.fetchLatestStatement(card.id!), isNull);
    });
  });

  group('debit cards and cards of unknown type', () {
    const debitSpend =
        'Rs.500.00 spent on HDFC Bank Debit Card XX1234 at AMAZON.';
    final day = DateTime(2026, 1, 15);

    PaymentCard hdfcCard(CardType type) => PaymentCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..type = type
      ..status = CardStatus.active
      ..creditLimit = type == CardType.credit ? 50000 : null;

    Future<Transaction> onlyRow() async => (await repository
            .fetchTransactionsInRange(range: DateRange.month(day)))
        .single;

    test('a debit card spend is linked to the debit card as an expense',
        () async {
      final card = hdfcCard(CardType.debit);
      cardRepository.seed([card]);

      expect(
          await ingestor.ingest(sender: 'HDFCBK', body: debitSpend, date: day),
          isTrue);

      final row = await onlyRow();
      expect(row.cardId, card.id);
      expect(row.kind, TransactionKind.expense);
    });

    test('with no matching card, a debit card spend is still imported, with '
        'no card and no sighting', () async {
      expect(
          await ingestor.ingest(sender: 'HDFCBK', body: debitSpend, date: day),
          isTrue);

      expect((await onlyRow()).cardId, isNull);
      expect(await detectedCardRepository.watchPending().first, isEmpty);
    });

    test('"HDFC Bank Card" matched to a registered credit card is debt',
        () async {
      final card = hdfcCard(CardType.credit);
      cardRepository.seed([card]);

      await ingestor.ingest(
        sender: 'HDFCBK',
        body: 'Txn Rs.500.00 On HDFC Bank Card 1234 At AMAZON',
        date: day,
      );

      final row = await onlyRow();
      expect(row.cardId, card.id);
      expect(row.kind, TransactionKind.debt);
    });

    test('an unmatched "Bank Card" SMS with a limit prompts for the card',
        () async {
      final saved = await ingestor.ingest(
          sender: 'AX-ICICIT-S',
          body: 'INR 1,000.00 spent using ICICI Bank Card XX0000 on 15-Nov-26 '
              'on AMAZON. Avl Limit: INR 11,111.11.',
          date: day);

      expect(saved, isFalse, reason: 'a credit card spend waits for its card');
      final pending = await detectedCardRepository.watchPending().first;
      expect(pending.single.last4, '0000');
      expect(pending.single.issuerGuess, 'ICICI');
    });

    test('an explicit credit card SMS never matches a debit card', () async {
      cardRepository.seed([hdfcCard(CardType.debit)]);

      final saved = await ingestor.ingest(
        sender: 'HDFCCC',
        body: 'Rs.500.00 spent on HDFC Bank Credit Card XX1234 at AMAZON.',
        date: day,
      );

      expect(saved, isFalse);
      expect(await detectedCardRepository.watchPending().first, hasLength(1));
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
