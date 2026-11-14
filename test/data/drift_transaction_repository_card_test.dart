import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/drift_card_repository.dart';
import 'package:fynans/adapters/data/drift_card_statement_repository.dart';
import 'package:fynans/adapters/data/drift_transaction_repository.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/missing_card_exception.dart';

import 'transaction_repository_contract.dart';

/// Card-aware TransactionRepository behaviour, against real Drift.
///
/// Kept out of `transaction_repository_contract.dart`: with
/// `PRAGMA foreign_keys = ON`, a transaction's cardId has to reference a real
/// row in the Cards table, which needs a CardRepository the shared,
/// TransactionRepository-only contract doesn't have. This is that missing
/// piece, sharing one AppDatabase between both repositories — same
/// requirement `main.dart`'s composition root has to honour.
void main() {
  late AppDatabase db;
  late DriftTransactionRepository transactions;
  late DriftCardRepository cards;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    transactions = DriftTransactionRepository(db);
    cards = DriftCardRepository(db);
  });

  tearDown(() => db.close());

  Future<int> seedCard({String issuer = 'HDFC', String last4 = '1234'}) async {
    final card = PaymentCard()
      ..issuer = issuer
      ..last4 = last4
      ..type = CardType.credit
      ..status = CardStatus.active
      ..creditLimit = 50000;
    await cards.saveCard(card);
    return card.id!;
  }

  group('the main list and card visibility', () {
    final julyAndAugust = DateRange(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 8, 31, 23, 59, 59),
    );

    Future<List<Transaction>> mainList() =>
        transactions.fetchTransactionsInRange(
          range: julyAndAugust,
          filter: const TransactionFilter.empty(),
        );

    test('card transactions are in the main list', () async {
      final cardId = await seedCard();
      await transactions.saveTransaction(txn(date: DateTime(2026, 7, 1)));
      await transactions
          .saveTransaction(txn(date: DateTime(2026, 7, 2), cardId: cardId));

      expect(await mainList(), hasLength(2));
    });

    test('a closed card hides only its transactions after the closing date',
        () async {
      final card = PaymentCard()..id = await seedCard();
      await transactions.saveTransaction(
          txn(date: DateTime(2026, 7, 31, 23), cardId: card.id, party: 'kept'));
      await transactions.saveTransaction(
          txn(date: DateTime(2026, 8, 2), cardId: card.id, party: 'hidden'));
      await transactions
          .saveTransaction(txn(date: DateTime(2026, 8, 2), party: 'no card'));

      await cards.closeCard(card, DateTime(2026, 7, 31));

      expect((await mainList()).map((t) => t.party), ['no card', 'kept']);
    });

    test('an untracked card hides all of its transactions', () async {
      final card = PaymentCard()..id = await seedCard();
      await transactions
          .saveTransaction(txn(date: DateTime(2026, 7, 2), cardId: card.id));
      await transactions.saveTransaction(txn(date: DateTime(2026, 7, 3)));

      await cards.untrackCard(card);

      final rows = await mainList();
      expect(rows, hasLength(1));
      expect(rows.single.cardId, isNull);
    });

    test('the live list shows the rows again when the card is restored',
        () async {
      final card = PaymentCard()..id = await seedCard();
      await transactions
          .saveTransaction(txn(date: DateTime(2026, 7, 2), cardId: card.id));
      await cards.untrackCard(card);

      final lengths = transactions
          .listenToTransactionsInRange(range: julyAndAugust)
          .map((rows) => rows.length);
      final expectation =
          expectLater(lengths, emitsInOrder([0, emitsThrough(1)]));
      await pumpEventQueue();

      await cards.restoreCard(card);

      await expectation;
    });

    test("the card's own list still shows the rows that its status hides",
        () async {
      final card = PaymentCard()..id = await seedCard();
      await transactions
          .saveTransaction(txn(date: DateTime(2026, 7, 2), cardId: card.id));

      await cards.untrackCard(card);

      expect(
        await transactions.listenToTransactionsForCard(card.id!).first,
        hasLength(1),
      );
    });
  });

  group('a write that names a missing card throws MissingCardException', () {
    const missing = 99;
    final throwsMissingCard = throwsA(isA<MissingCardException>()
        .having((e) => e.cardId, 'cardId', missing));

    test('importTransaction', () {
      expect(
          transactions.importTransaction(
              txn(date: DateTime(2026, 7, 1), smsId: 'a', cardId: missing)),
          throwsMissingCard);
    });

    test('relinkTransactionToCard', () async {
      await transactions
          .saveTransaction(txn(date: DateTime(2026, 7, 1), smsId: 'a'));

      expect(transactions.relinkTransactionToCard(smsId: 'a', cardId: missing),
          throwsMissingCard);
    });

    test('updateTransaction', () async {
      final saved = txn(date: DateTime(2026, 7, 1));
      await transactions.saveTransaction(saved);

      expect(transactions.updateTransaction(saved..cardId = missing),
          throwsMissingCard);
    });

    test('importStatement', () {
      expect(
          DriftCardStatementRepository(db).importStatement(CardStatement()
            ..cardId = missing
            ..statementDate = DateTime(2026, 7, 1)
            ..smsId = 'a'),
          throwsMissingCard);
    });
  });

  test('listenToTransactionsForCard is all-time and card-scoped', () async {
    final card1 = await seedCard(issuer: 'HDFC', last4: '1234');
    final card2 = await seedCard(issuer: 'SBI Card', last4: '5678');
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), cardId: card1));
    await transactions
        .saveTransaction(txn(date: DateTime(2020, 1, 1), cardId: card1));
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), cardId: card2));

    final forCard1 =
        await transactions.listenToTransactionsForCard(card1).first;

    expect(forCard1, hasLength(2));
    expect(forCard1.every((t) => t.cardId == card1), isTrue);
  });

  test('distinct helpers exclude card transactions', () async {
    final cardId = await seedCard();
    await transactions.saveTransaction(txn(
      date: DateTime(2026, 7, 1),
      party: 'Regular Party',
      group: ['Regular Group'],
    ));
    await transactions.saveTransaction(txn(
      date: DateTime(2026, 7, 2),
      cardId: cardId,
      party: 'Card Merchant',
      group: ['Card Group'],
    ));

    expect(await transactions.getAllParties(), ['Regular Party']);
    expect(await transactions.getAllGroups(), ['Regular Group']);
  });

  test('cardAvailableLimit round-trips', () async {
    final cardId = await seedCard();
    final t = txn(date: DateTime(2026, 7, 1), cardId: cardId)
      ..cardAvailableLimit = 48750.0;
    await transactions.saveTransaction(t);

    final stored =
        (await transactions.listenToTransactionsForCard(cardId).first).single;
    expect(stored.cardAvailableLimit, 48750.0);
  });

  test('the database refuses to delete a card that a transaction refers to',
      () async {
    final card = PaymentCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..type = CardType.credit
      ..status = CardStatus.active
      ..creditLimit = 50000;
    await cards.saveCard(card);
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), cardId: card.id));

    // The safety net under RemoveCard: even a bug that calls deleteCard on a
    // card with history cannot strip the card from its transactions.
    await expectLater(cards.deleteCard(card), throwsA(anything));
    expect(await cards.fetchCards(), hasLength(1));
  });

  test(
      'relinkTransactionToCard links a card SMS row that was imported '
      'without a card', () async {
    final card = PaymentCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..type = CardType.credit
      ..status = CardStatus.active
      ..creditLimit = 50000;
    await cards.saveCard(card);
    // As if the SMS was imported before the parser recognised it as a card
    // SMS: the row has the smsId, but no card.
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), smsId: 'sms-1'));

    final relinked = await transactions.relinkTransactionToCard(
      smsId: 'sms-1',
      cardId: card.id!,
      cardAvailableLimit: 47500,
    );

    expect(relinked, isTrue);
    final forCard =
        await transactions.listenToTransactionsForCard(card.id!).first;
    expect(forCard, hasLength(1));
    expect(forCard.single.cardAvailableLimit, 47500);
  });

  test(
      'relinkTransactionToCard does not clobber a row already linked to a '
      'different card', () async {
    final cardA = await seedCard(issuer: 'HDFC', last4: '1234');
    final cardB = await seedCard(issuer: 'SBI Card', last4: '5678');
    await transactions.saveTransaction(
      txn(date: DateTime(2026, 7, 1), cardId: cardA, smsId: 'sms-2'),
    );

    final relinked = await transactions.relinkTransactionToCard(
      smsId: 'sms-2',
      cardId: cardB,
    );

    expect(relinked, isFalse);
    final forCardA =
        await transactions.listenToTransactionsForCard(cardA).first;
    expect(forCardA, hasLength(1), reason: 'must not have been reassigned');
  });
}
