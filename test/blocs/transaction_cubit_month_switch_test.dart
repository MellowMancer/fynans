import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_state.dart';
import 'package:fynans/entities/transaction.dart';

import '../fakes/fake_transaction_repository.dart';

Transaction _txn(double amount, DateTime date) => Transaction()
  ..amount = amount
  ..date = date
  ..tags = <String>[]
  ..group = <String>[]
  ..party = 'x'
  ..isCredit = false;

void main() {
  test('switching month re-subscribes and emits the new month', () async {
    final repo = FakeTransactionRepository()
      ..seed([
        _txn(100, DateTime(2026, 7, 5)),
        _txn(50, DateTime(2026, 6, 5)),
        _txn(25, DateTime(2026, 6, 6)),
      ]);
    addTearDown(repo.dispose);

    final cubit = TransactionCubit(repo);
    addTearDown(cubit.close);

    await cubit.fetchTransactionsForMonth(DateTime(2026, 7));
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as TransactionLoadSuccess).transactions, hasLength(1));

    // The regression: this second call used to hang on `await cancel()`, so the
    // cubit stayed on July forever.
    await cubit
        .fetchTransactionsForMonth(DateTime(2026, 6))
        .timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);

    expect(repo.subscribeCount, 2, reason: 'must re-subscribe for June');
    final state = cubit.state;
    expect(state, isA<TransactionLoadSuccess>());
    expect((state as TransactionLoadSuccess).transactions, hasLength(2),
        reason: 'should now show June, not July');
    expect(state.summary.totalExpenses, 75);
  });
}
