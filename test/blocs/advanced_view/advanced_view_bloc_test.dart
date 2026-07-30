import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/date_range_presets.dart';
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
    registerFallbackValue(DateRange.month(DateTime(2026)));
    registerFallbackValue(const TransactionFilter.empty());
  });

  group('AdvancedViewBloc defaults', () {
    test('starts on This Month covering the current calendar month', () {
      final repo = _MockTransactionRepository();
      final bloc = AdvancedViewBloc(repo);
      addTearDown(bloc.close);

      final state = bloc.state as AdvancedViewLoadSuccess;
      final now = DateTime.now();

      expect(state.preset, DateRangePreset.thisMonth);
      expect(state.range.start, DateTime(now.year, now.month, 1));
      expect(state.range.contains(now), isTrue);
      expect(state.range.isSingleDay, isFalse,
          reason: 'should be the whole month, not just today');
    });
  });

  group('AdvancedViewBloc recovery', () {
    test('a stream failure is not terminal — a range change still refetches',
        () async {
      final controllers = <StreamController<List<Transaction>>>[];
      final repo = _MockTransactionRepository();
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) {
        final controller = StreamController<List<Transaction>>();
        controllers.add(controller);
        addTearDown(controller.close);
        return controller.stream;
      });

      final bloc = AdvancedViewBloc(
        repo,
        initialRange: DateRange.month(DateTime(2026, 7)),
      );
      addTearDown(bloc.close);

      bloc.add(AdvancedViewDataFetched());
      await Future<void>.delayed(Duration.zero);
      controllers[0].addError(StateError('boom'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<AdvancedViewFailure>());

      // From the failure state the user changes the range; this must recover.
      bloc.add(AdvancedViewRangeChanged(
        DateRange.month(DateTime(2026, 6)),
        DateRangePreset.thisMonth,
      ));
      await Future<void>.delayed(Duration.zero);
      controllers.last.add([_txn(amount: 10, date: DateTime(2026, 6, 2))]);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<AdvancedViewLoadSuccess>(),
          reason: 'failure must not be a dead end');
      expect((bloc.state as AdvancedViewLoadSuccess).range.start,
          DateTime(2026, 6, 1));
    });

    test('a snapshot queued before a range change cannot revert it', () async {
      final controllers = <StreamController<List<Transaction>>>[];
      final repo = _MockTransactionRepository();
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) {
        final controller = StreamController<List<Transaction>>();
        controllers.add(controller);
        addTearDown(controller.close);
        return controller.stream;
      });

      final bloc = AdvancedViewBloc(
        repo,
        initialRange: DateRange.month(DateTime(2026, 7)),
      );
      addTearDown(bloc.close);

      bloc.add(AdvancedViewDataFetched());
      await Future<void>.delayed(Duration.zero);
      controllers[0].add([_txn(amount: 10, date: DateTime(2026, 7, 1))]);
      await Future<void>.delayed(Duration.zero);

      // Queue the range change, then let the OLD subscription deliver.
      bloc.add(AdvancedViewRangeChanged(
        DateRange.month(DateTime(2026, 6)),
        DateRangePreset.thisMonth,
      ));
      controllers[0].add([_txn(amount: 99, date: DateTime(2026, 7, 2))]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = bloc.state;
      if (state is AdvancedViewLoadSuccess) {
        expect(state.range.start, DateTime(2026, 6, 1),
            reason: 'a stale snapshot must not restore the previous range');
      }
    });
  });

  group('AdvancedViewBloc reactivity', () {
    late _MockTransactionRepository repo;

    setUp(() => repo = _MockTransactionRepository());

    test('re-emits grouped success state on each stream snapshot', () async {
      final controller = StreamController<List<Transaction>>();
      addTearDown(controller.close);
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) => controller.stream);

      final bloc = AdvancedViewBloc(repo, initialRange: DateRange.month(DateTime(2026, 7)));
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AdvancedViewLoading>(),
          isA<AdvancedViewLoadSuccess>()
              .having((s) => s.summary.totalExpenses, 'totalExpenses', 100)
              .having((s) => s.hierarchicalData.single.name, 'monthNode',
                  'Jul 2026')
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
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) => controller.stream);

      final bloc = AdvancedViewBloc(repo, initialRange: DateRange.month(DateTime(2026, 7)));
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

    test('cancels the previous subscription on range change', () async {
      final controllers = <StreamController<List<Transaction>>>[];
      when(() => repo.listenToTransactionsInRange(
            range: any(named: 'range'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) {
        final controller = StreamController<List<Transaction>>();
        controllers.add(controller);
        addTearDown(controller.close);
        return controller.stream;
      });

      final bloc = AdvancedViewBloc(repo, initialRange: DateRange.month(DateTime(2026, 7)));
      addTearDown(bloc.close);

      bloc.add(AdvancedViewDataFetched());
      await Future<void>.delayed(Duration.zero);
      // Reach a success state so AdvancedViewRangeChanged is not gated out.
      controllers[0].add([_txn(amount: 10, date: DateTime(2026, 7, 1))]);
      await Future<void>.delayed(Duration.zero);
      bloc.add(AdvancedViewRangeChanged(
        DateRange.month(DateTime(2026, 8)),
        DateRangePreset.thisMonth,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(controllers, hasLength(2));
      expect(controllers[0].hasListener, isFalse,
          reason: 'prior subscription cancelled on re-fetch');
      expect(controllers[1].hasListener, isTrue);
    });
  });
}
