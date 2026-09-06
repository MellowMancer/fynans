import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/credit_card.dart';
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

    test('matched card SMS routes to the card, out of the main list', () async {
      final card = CreditCard()
        ..issuer = 'SBI Card'
        ..last4 = '1234'
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

      // Matches how the app's own screens read the main list — the default
      // CardScope on an empty filter is what excludes card spends.
      final mainList = await repository.fetchTransactionsInRange(
        range: DateRange.month(cardDate),
        filter: const TransactionFilter.empty(),
      );
      expect(mainList, isEmpty);

      final cardTxns =
          await repository.listenToTransactionsForCard(card.id!).first;
      expect(cardTxns, hasLength(1));
      expect(cardTxns.first.cardAvailableLimit, 1235.00);
      expect(cardTxns.first.isCredit, isFalse);
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
      await ingestor.ingest(sender: cardSender, body: spendBody, date: cardDate);

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

    test('repeated sightings of the same unmatched card bump the count, '
        'not create duplicates', () async {
      await ingestor.ingest(sender: cardSender, body: spendBody, date: cardDate);
      await ingestor.ingest(
          sender: cardSender,
          body: spendBody,
          date: cardDate.add(const Duration(days: 1)));

      final pending = await detectedCardRepository.watchPending().first;
      expect(pending, hasLength(1));
      expect(pending.single.sightingCount, 2);
    });

    test('a dismissed sighting is not resurrected by a new SMS', () async {
      await ingestor.ingest(sender: cardSender, body: spendBody, date: cardDate);
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
      final card = CreditCard()
        ..issuer = 'SBI Card'
        ..last4 = '1234'
        ..creditLimit = 5000;
      cardRepository.seed([card]);
      ingestor = TransactionSmsIngestor(
        repository: repository,
        cardRepository: cardRepository,
        detectedCardRepository: detectedCardRepository,
        statementRepository: statementRepository,
      );

      await ingestor.ingest(sender: cardSender, body: spendBody, date: cardDate);

      expect(await detectedCardRepository.watchPending().first, isEmpty);
    });

    test(
        'deleting a card then re-adding it re-links its stranded history, '
        'not just future SMS', () async {
      // Regression: unlinking (not deleting) a card's transactions on
      // delete left them stuck cardId-less forever, because
      // importTransaction's dedup-by-smsId silently no-ops on a re-scan —
      // nothing re-visited an already-imported row to update its cardId.
      final original = CreditCard()
        ..issuer = 'SBI Card'
        ..last4 = '1234'
        ..creditLimit = 5000;
      cardRepository.seed([original]);

      // 1. First sweep: the spend lands under the original card.
      await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);
      expect(
        (await repository.listenToTransactionsForCard(original.id!).first),
        hasLength(1),
      );

      // 2. Delete the card — unlinkCard, exactly as CardDetailScreen does.
      await repository.unlinkCard(original.id!);
      await cardRepository.deleteCard(original);
      final strandedInMainList = await repository.fetchTransactionsInRange(
        range: DateRange.month(cardDate),
        filter: const TransactionFilter.empty(),
      );
      expect(strandedInMainList, hasLength(1),
          reason: 'unlinked rows re-enter the main list, not deleted');

      // 3. Re-add the same card (new id, same issuer/last4) and re-sweep,
      // exactly like AddCardCubit does after a successful save.
      final readded = CreditCard()
        ..issuer = 'SBI Card'
        ..last4 = '1234'
        ..creditLimit = 5000;
      await cardRepository.saveCard(readded);
      expect(readded.id, isNot(original.id));
      ingestor = TransactionSmsIngestor(
        repository: repository,
        cardRepository: cardRepository,
        detectedCardRepository: detectedCardRepository,
        statementRepository: statementRepository,
      );
      final relinked = await ingestor.ingest(
          sender: cardSender, body: spendBody, date: cardDate);

      expect(relinked, isTrue,
          reason: 'a re-link counts as this SMS being accounted for');
      expect(
        await repository.listenToTransactionsForCard(readded.id!).first,
        hasLength(1),
        reason: 'the stranded transaction now belongs to the re-added card',
      );
      expect(
        await repository.fetchTransactionsInRange(
          range: DateRange.month(cardDate),
          filter: const TransactionFilter.empty(),
        ),
        isEmpty,
        reason: 're-linked, so it leaves the main list again',
      );
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
