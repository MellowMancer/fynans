import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';

import '../support/builders.dart';
import 'fake_card_repository.dart';
import 'fake_transaction_repository.dart';

/// The fake stands in for the real repository in most of the suite, so where
/// the two disagree, tests pass against behaviour the app does not have. The
/// general rules run against both through `transaction_repository_contract`.
/// These pin the card behaviour, which `drift_transaction_repository_card_test`
/// checks for Drift.
void main() {
  final august = DateTime(2026, 8, 1);

  Future<List<Transaction>> inAugust(FakeTransactionRepository repo) =>
      repo.fetchTransactionsInRange(range: DateRange.month(august));

  group('cards', () {
    test('the default filter keeps card transactions', () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(aTransaction(date: august));
      await repo.saveTransaction(aTransaction(date: august, cardId: 1));

      final rows = await repo.fetchTransactionsInRange(
        range: DateRange.month(august),
        filter: const TransactionFilter.empty(),
      );
      expect(rows, hasLength(2));
    });

    test('with a card repository, an untracked card hides its rows, like Drift',
        () async {
      final cards = FakeCardRepository();
      final card = aCard();
      await cards.saveCard(card);
      final repo = FakeTransactionRepository(cards: cards);
      await repo.saveTransaction(aTransaction(date: august));
      await repo.saveTransaction(aTransaction(date: august, cardId: card.id));

      await cards.untrackCard(card);

      final rows = await inAugust(repo);
      expect(rows, hasLength(1));
      expect(rows.single.cardId, isNull);
    });

    test('listenToTransactionsForCard returns only that card, all-time',
        () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(aTransaction(date: august, cardId: 1));
      await repo.saveTransaction(aTransaction(date: august, cardId: 2));
      await repo.saveTransaction(
          aTransaction(date: DateTime(2020, 1, 1), cardId: 1));

      final forCard1 = await repo.listenToTransactionsForCard(1).first;
      expect(forCard1, hasLength(2));
      expect(forCard1.every((t) => t.cardId == 1), isTrue);
    });

    test(
        'relinkTransactionToCard attaches cardId to an unlinked row matching '
        'the smsId', () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(aTransaction(date: august, smsId: 'abc123'));

      final relinked = await repo.relinkTransactionToCard(
        kind: TransactionKind.debt,
        smsId: 'abc123',
        cardId: 7,
        cardAvailableLimit: 4500,
      );

      expect(relinked, isTrue);
      final stored = (await inAugust(repo)).single;
      expect(stored.cardId, 7);
      expect(stored.cardAvailableLimit, 4500);
    });

    test(
        'relinkTransactionToCard does not touch a row already linked to a '
        'different card', () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(
          aTransaction(date: august, smsId: 'abc123', cardId: 1));

      final relinked = await repo.relinkTransactionToCard(
          kind: TransactionKind.debt, smsId: 'abc123', cardId: 2);

      expect(relinked, isFalse);
      final stored = (await inAugust(repo)).single;
      expect(stored.cardId, 1, reason: 'must not clobber an existing link');
    });

    test('relinkTransactionToCard returns false when no row has that smsId',
        () async {
      final repo = FakeTransactionRepository();
      expect(
        await repo.relinkTransactionToCard(
            kind: TransactionKind.debt, smsId: 'missing', cardId: 1),
        isFalse,
      );
    });

    test('distinct helpers exclude card transactions', () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(aTransaction(
          date: august, party: 'Regular Party', group: ['Regular Group']));
      await repo.saveTransaction(aTransaction(
          date: august,
          cardId: 1,
          party: 'Card Merchant',
          group: ['Card Group']));

      expect(await repo.getAllParties(), ['Regular Party']);
      expect(await repo.getAllGroups(), ['Regular Group']);
    });
  });
}
