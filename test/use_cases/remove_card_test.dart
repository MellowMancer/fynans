import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/remove_card.dart';

import '../fakes/fake_card_repository.dart';
import '../fakes/fake_card_statement_repository.dart';
import '../fakes/fake_transaction_repository.dart';
import '../support/builders.dart';

void main() {
  late FakeCardRepository cards;
  late FakeTransactionRepository transactions;
  late FakeCardStatementRepository statements;
  late RemoveCard removeCard;
  late PaymentCard card;

  setUp(() async {
    cards = FakeCardRepository();
    transactions = FakeTransactionRepository();
    statements = FakeCardStatementRepository();
    removeCard = RemoveCard(cards, transactions, statements);
    card = aCard();
    await cards.saveCard(card);
  });

  Future<void> addSpend() =>
      transactions.saveTransaction(aTransaction(card: card));

  Future<void> addStatement() => statements
      .importStatement(aStatement(card: card, smsId: 'statement-1'));

  group('removalFor', () {
    test('a card with no transactions and no statements can be deleted',
        () async {
      expect(await removeCard.removalFor(card), CardRemoval.delete);
    });

    test('a card with a transaction must be retired', () async {
      await addSpend();

      expect(await removeCard.removalFor(card), CardRemoval.retire);
    });

    test('a card with only a statement must be retired', () async {
      await addStatement();

      expect(await removeCard.removalFor(card), CardRemoval.retire);
    });
  });

  group('delete', () {
    test('deletes a card with no history', () async {
      await removeCard.delete(card);

      expect(await cards.fetchCards(), isEmpty);
    });

    test('refuses a card with history, and keeps the card', () async {
      await addSpend();

      await expectLater(removeCard.delete(card), throwsStateError);
      expect(await cards.fetchCards(), hasLength(1));
    });
  });

  test('close stores the start of the closing day', () async {
    await addSpend();

    await removeCard.close(card, DateTime(2026, 7, 31, 18, 45));

    final stored = (await cards.fetchCards()).single;
    expect(stored.status, CardStatus.closed);
    expect(stored.closedOn, DateTime(2026, 7, 31));
  });

  test('untrack keeps the card and its transactions', () async {
    await addSpend();

    await removeCard.untrack(card);

    final stored = (await cards.fetchCards()).single;
    expect(stored.status, CardStatus.untracked);
    expect(await transactions.listenToTransactionsForCard(card.id!).first,
        hasLength(1));
  });

  test('restore makes a retired card active again', () async {
    await addSpend();
    await removeCard.untrack(card);

    await removeCard.restore(card);

    final stored = (await cards.fetchCards()).single;
    expect(stored.status, CardStatus.active);
    expect(stored.closedOn, isNull);
  });

  group('HiddenTransactions.of', () {
    final transactions = [
      aTransaction(
        amount: 100,
        date: DateTime(2026, 7, 30),
        kind: TransactionKind.debt,
      ),
      aTransaction(
        amount: 200,
        date: DateTime(2026, 7, 31, 22),
        kind: TransactionKind.debt,
      ),
      aTransaction(
        amount: 400,
        date: DateTime(2026, 8, 2),
        kind: TransactionKind.debt,
      ),
    ];

    test('a closed card counts only the transactions after the closing date',
        () {
      final hidden = HiddenTransactions.of(
          transactions, CardStatus.closed, DateTime(2026, 7, 31));

      expect(hidden.count, 1);
      expect(hidden.total, 400);
    });

    test('an untracked card counts every transaction', () {
      final hidden =
          HiddenTransactions.of(transactions, CardStatus.untracked, null);

      expect(hidden.count, 3);
      expect(hidden.total, 700);
    });
  });
}
