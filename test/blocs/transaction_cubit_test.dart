import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/blocs/transaction/transaction_state.dart';
import 'package:fynans/models/transaction.dart';

import '../fakes/fake_transaction_repository.dart';

Transaction _txn({
  required double amount,
  required DateTime date,
  required bool isCredit,
  List<String> tags = const [],
  List<String> group = const [],
  String party = 'Test',
}) {
  return Transaction()
    ..amount = amount
    ..date = date
    ..isCredit = isCredit
    ..tags = List.of(tags)
    ..group = List.of(group)
    ..party = party
    ..note = null;
}

/// Example test proving the testing environment: a real production cubit driven
/// by the in-memory [FakeTransactionRepository], asserted via the stream. This
/// is the template for the BLoC/repository tests the project is missing.
void main() {
  group('TransactionCubit', () {
    late FakeTransactionRepository repo;

    setUp(() => repo = FakeTransactionRepository());

    test('emits [InProgress, Success] with a summary computed from the repo',
        () async {
      repo.seed([
        _txn(amount: 120, date: DateTime(2026, 7, 5), isCredit: false, tags: ['food']),
        _txn(amount: 500, date: DateTime(2026, 7, 6), isCredit: true),
      ]);
      final cubit = TransactionCubit(repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<TransactionLoadInProgress>(),
          isA<TransactionLoadSuccess>()
              .having((s) => s.summary.totalExpenses, 'totalExpenses', 120)
              .having((s) => s.summary.totalIncome, 'totalIncome', 500)
              .having((s) => s.transactions.length, 'transactions', 2),
        ]),
      );

      await cubit.fetchTransactionsForMonth(DateTime(2026, 7));
      await expectation;
    });

    test('excludes transactions outside the selected month', () async {
      repo.seed([
        _txn(amount: 100, date: DateTime(2026, 7, 10), isCredit: false),
        _txn(amount: 999, date: DateTime(2026, 6, 30), isCredit: false),
      ]);
      final cubit = TransactionCubit(repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<TransactionLoadInProgress>(),
          isA<TransactionLoadSuccess>()
              .having((s) => s.transactions.length, 'transactions', 1)
              .having((s) => s.summary.totalExpenses, 'totalExpenses', 100),
        ]),
      );

      await cubit.fetchTransactionsForMonth(DateTime(2026, 7));
      await expectation;
    });
  });
}
