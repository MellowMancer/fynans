import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

Transaction _txn({
  required double amount,
  required DateTime date,
  bool isCredit = false,
}) {
  return Transaction()
    ..amount = amount
    ..date = date
    ..isCredit = isCredit
    ..tags = <String>[]
    ..group = <String>[]
    ..party = 'Test'
    ..note = null;
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const TransactionFilter.empty());
  });

  group('AdvancedViewBloc reactivity', () {
    late _MockTransactionRepository repo;

    setUp(() => repo = _MockTransactionRepository());

    test('re-emits grouped success state on each stream snapshot', () async {
      final controller = StreamController<List<Transaction>>();
      addTearDown(controller.close);
      when(() => repo.listenToTransactionsForMonth(
            month: any(named: 'month'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) => controller.stream);

      final bloc = AdvancedViewBloc(repo, initialMonth: DateTime(2026, 7));
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AdvancedViewLoading>(),
          isA<AdvancedViewLoadSuccess>()
              .having((s) => s.summary.totalExpenses, 'totalExpenses', 100)
              .having((s) => s.hierarchicalData.single.name, 'monthNode',
                  'July 2026')
              .having((s) => s.hierarchicalData.single.transactionCount,
                  'count', 1),
          isA<AdvancedViewLoadSuccess>()
              .having((s) => s.summary.totalExpenses, 'totalExpenses', 300)
              .having((s) => s.hierarchicalData.single.transactionCount,
                  'count', 2),
        ]),
      );

      bloc.add(AdvancedViewDataFetched());
      await Future<void>.delayed(Duration.zero);
      controller.add([_txn(amount: 100, date: DateTime(2026, 7, 5))]);
      await Future<void>.delayed(Duration.zero);
      // Simulate a second box write producing a new snapshot.
      controller.add([
        _txn(amount: 100, date: DateTime(2026, 7, 5)),
        _txn(amount: 200, date: DateTime(2026, 7, 6)),
      ]);

      await expectation;
    });

    test('forwards stream errors to AdvancedViewFailure', () async {
      final controller = StreamController<List<Transaction>>();
      addTearDown(controller.close);
      when(() => repo.listenToTransactionsForMonth(
            month: any(named: 'month'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) => controller.stream);

      final bloc = AdvancedViewBloc(repo, initialMonth: DateTime(2026, 7));
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AdvancedViewLoading>(),
          isA<AdvancedViewFailure>()
              .having((s) => s.error, 'error', contains('boom')),
        ]),
      );

      bloc.add(AdvancedViewDataFetched());
      await Future<void>.delayed(Duration.zero);
      controller.addError(StateError('boom'));

      await expectation;
    });

    test('cancels the previous subscription on month change', () async {
      final controllers = <StreamController<List<Transaction>>>[];
      when(() => repo.listenToTransactionsForMonth(
            month: any(named: 'month'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) {
        final controller = StreamController<List<Transaction>>();
        controllers.add(controller);
        addTearDown(controller.close);
        return controller.stream;
      });

      final bloc = AdvancedViewBloc(repo, initialMonth: DateTime(2026, 7));
      addTearDown(bloc.close);

      bloc.add(AdvancedViewDataFetched());
      await Future<void>.delayed(Duration.zero);
      // Reach a success state so AdvancedViewMonthChanged is not gated out.
      controllers[0].add([_txn(amount: 10, date: DateTime(2026, 7, 1))]);
      await Future<void>.delayed(Duration.zero);
      bloc.add(AdvancedViewMonthChanged(DateTime(2026, 8)));
      await Future<void>.delayed(Duration.zero);

      expect(controllers, hasLength(2));
      expect(controllers[0].hasListener, isFalse,
          reason: 'prior subscription cancelled on re-fetch');
      expect(controllers[1].hasListener, isTrue);
    });
  });
}
