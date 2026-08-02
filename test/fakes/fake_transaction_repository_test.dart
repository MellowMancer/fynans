import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';

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
}
