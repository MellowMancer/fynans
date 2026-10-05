import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';

import 'fake_transaction_repository.dart';

/// The fake stands in for the real repository in most of the suite, so where
/// the two disagree, tests pass against behaviour the app does not have. These
/// pin the places that are easy to let drift; Slice D folds them into a shared
/// contract run against both implementations.
void main() {
  Transaction txn() => Transaction()
    ..amount = 100
    ..date = DateTime(2026, 8, 1)
    ..tags = <String>[]
    ..group = <String>[]
    ..party = 'x'
    ..isCredit = false;

  test('saving assigns an id', () async {
    final repo = FakeTransactionRepository();
    final t = txn();

    await repo.saveTransaction(t);

    expect(t.id, isNotNull);
  });

  test('deleting an unsaved record throws, as the real repository does',
      () async {
    final repo = FakeTransactionRepository();

    expect(
      () => repo.deleteTransaction(txn()),
      throwsA(isA<StateError>()),
    );
  });

  test('delete matches on id, not object identity', () async {
    final repo = FakeTransactionRepository();
    final saved = txn();
    await repo.saveTransaction(saved);

    await repo.deleteTransaction(txn()..id = saved.id);

    final remaining = await repo.fetchTransactionsInRange(
      range: DateRange.month(DateTime(2026, 8)),
    );
    expect(remaining, isEmpty);
  });

  group('CardScope', () {
    test('default filter excludes card transactions; null filter does not',
        () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(txn());
      await repo.saveTransaction(txn()..cardId = 1);

      final excluded = await repo.fetchTransactionsInRange(
        range: DateRange.month(DateTime(2026, 8)),
        filter: const TransactionFilter.empty(),
      );
      expect(excluded, hasLength(1));

      final unfiltered = await repo.fetchTransactionsInRange(
        range: DateRange.month(DateTime(2026, 8)),
      );
      expect(unfiltered, hasLength(2));
    });

    test('listenToTransactionsForCard returns only that card, all-time',
        () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(txn()..cardId = 1);
      await repo.saveTransaction(txn()..cardId = 2);
      await repo.saveTransaction(
        txn()
          ..cardId = 1
          ..date = DateTime(2020, 1, 1),
      );

      final forCard1 = await repo.listenToTransactionsForCard(1).first;
      expect(forCard1, hasLength(2));
      expect(forCard1.every((t) => t.cardId == 1), isTrue);
    });

    test('unlinkCard nulls cardId on every transaction for that card',
        () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(txn()..cardId = 1);
      await repo.saveTransaction(txn()..cardId = 1);
      await repo.saveTransaction(txn()..cardId = 2);

      await repo.unlinkCard(1);

      final all = await repo.fetchTransactionsInRange(
        range: DateRange.month(DateTime(2026, 8)),
      );
      expect(all.where((t) => t.cardId == 1), isEmpty);
      expect(all.where((t) => t.cardId == 2), hasLength(1));
    });

    test(
        'relinkTransactionToCard attaches cardId to an unlinked row matching '
        'the smsId', () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(txn()..smsId = 'abc123'); // cardId null

      final relinked = await repo.relinkTransactionToCard(
        smsId: 'abc123',
        cardId: 7,
        cardAvailableLimit: 4500,
      );

      expect(relinked, isTrue);
      final stored = (await repo.fetchTransactionsInRange(
        range: DateRange.month(DateTime(2026, 8)),
      ))
          .single;
      expect(stored.cardId, 7);
      expect(stored.cardAvailableLimit, 4500);
    });

    test(
        'relinkTransactionToCard does not touch a row already linked to a '
        'different card', () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(txn()
        ..smsId = 'abc123'
        ..cardId = 1);

      final relinked =
          await repo.relinkTransactionToCard(smsId: 'abc123', cardId: 2);

      expect(relinked, isFalse);
      final stored = (await repo.fetchTransactionsInRange(
        range: DateRange.month(DateTime(2026, 8)),
      ))
          .single;
      expect(stored.cardId, 1, reason: 'must not clobber an existing link');
    });

    test('relinkTransactionToCard returns false when no row has that smsId',
        () async {
      final repo = FakeTransactionRepository();
      expect(
        await repo.relinkTransactionToCard(smsId: 'missing', cardId: 1),
        isFalse,
      );
    });

    test('distinct helpers exclude card transactions', () async {
      final repo = FakeTransactionRepository();
      await repo.saveTransaction(txn()
        ..party = 'Regular Party'
        ..group = ['Regular Group']);
      await repo.saveTransaction(txn()
        ..cardId = 1
        ..party = 'Card Merchant'
        ..group = ['Card Group']);

      expect(await repo.getAllParties(), ['Regular Party']);
      expect(await repo.getAllGroups(), ['Regular Group']);
    });
  });
}
