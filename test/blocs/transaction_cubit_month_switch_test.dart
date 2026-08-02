import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_state.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// Mirrors the REAL repository: a controller-backed stream that stays open
/// until cancelled.
class _LongLivedRepository implements TransactionRepository {
  _LongLivedRepository(this.byMonth);

  final Map<int, List<Transaction>> byMonth;
  final _keepAlive = StreamController<void>.broadcast();
  int subscribeCount = 0;

  @override
  Stream<List<Transaction>> listenToTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  }) {
    subscribeCount++;
    late final StreamController<List<Transaction>> controller;
    StreamSubscription<void>? watcher;
    controller = StreamController<List<Transaction>>(
      onListen: () {
        controller.add(byMonth[range.start.month] ?? const []);
        watcher = _keepAlive.stream.listen(
          (_) => controller.add(byMonth[range.start.month] ?? const []),
        );
      },
      onCancel: () async => watcher?.cancel(),
    );
    return controller.stream;
  }

  void dispose() => _keepAlive.close();

  @override
  Future<List<Transaction>> fetchTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  }) async => byMonth[range.start.month] ?? const [];

  @override
  Future<void> saveTransaction(Transaction transaction) async {}
  @override
  Future<void> deleteTransaction(Transaction transaction) async {}
  @override
  Future<bool> importTransaction(Transaction transaction) async => false;
  @override
  Future<int> purgeLegacySmsRecords() async => 0;
  @override
  Future<List<String>> getAllGroups() async => const [];
  @override
  Future<List<String>> getAllUniqueTags() async => const [];
  @override
  Future<List<String>> getAllParties() async => const [];
}

Transaction _txn(double amount, DateTime date) => Transaction()
  ..amount = amount
  ..date = date
  ..tags = <String>[]
  ..group = <String>[]
  ..party = 'x'
  ..isCredit = false;

void main() {
  test('switching month re-subscribes and emits the new month', () async {
    final repo = _LongLivedRepository({
      7: [_txn(100, DateTime(2026, 7, 5))],
      6: [_txn(50, DateTime(2026, 6, 5)), _txn(25, DateTime(2026, 6, 6))],
    });
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
