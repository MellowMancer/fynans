import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_state.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:mocktail/mocktail.dart';

import '../fakes/fake_transaction_repository.dart';
import '../fakes/mock_transaction_repository.dart';

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
/// by the in-memory [FakeTransactionRepository], asserted via the stream.
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

  group('TransactionCubit subscription lifecycle', () {
    late MockTransactionRepository repo;

    setUpAll(() => registerFallbackValue(DateRange.month(DateTime(2026))));

    setUp(() => repo = MockTransactionRepository());

    test('cancels the previous subscription when re-fetching', () async {
      final controllers = <StreamController<List<Transaction>>>[];
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
          )).thenAnswer((_) {
        final controller = StreamController<List<Transaction>>();
        controllers.add(controller);
        addTearDown(controller.close);
        return controller.stream;
      });

      final cubit = TransactionCubit(repo);
      addTearDown(cubit.close);

      await cubit.fetchTransactionsForMonth(DateTime(2026, 7));
      await cubit.fetchTransactionsForMonth(DateTime(2026, 8));

      expect(controllers, hasLength(2));
      expect(
        controllers[0].hasListener,
        isFalse,
        reason: 'the first subscription must be cancelled on the second fetch',
      );
      expect(controllers[1].hasListener, isTrue);
    });

    test('does not emit a success state after close', () async {
      late StreamController<List<Transaction>> controller;
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
          )).thenAnswer((_) {
        controller = StreamController<List<Transaction>>();
        addTearDown(controller.close);
        return controller.stream;
      });

      final cubit = TransactionCubit(repo);
      final states = <TransactionState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(sub.cancel);

      await cubit.fetchTransactionsForMonth(DateTime(2026, 7));
      await cubit.close();

      controller.add([
        _txn(amount: 10, date: DateTime(2026, 7, 1), isCredit: false),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(states.whereType<TransactionLoadSuccess>(), isEmpty);
    });

    test('forwards stream errors to TransactionLoadFailure', () async {
      final controller = StreamController<List<Transaction>>();
      addTearDown(controller.close);
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
          )).thenAnswer((_) => controller.stream);

      final cubit = TransactionCubit(repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<TransactionLoadInProgress>(),
          isA<TransactionLoadFailure>()
              .having((s) => s.error, 'error', contains('boom')),
        ]),
      );

      await cubit.fetchTransactionsForMonth(DateTime(2026, 7));
      controller.addError(StateError('boom'));
      await expectation;
    });
  });
}
