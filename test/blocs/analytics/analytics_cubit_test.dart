import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_cubit.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_state.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';

import '../../fakes/fake_transaction_repository.dart';

Transaction _txn({
  required double amount,
  required DateTime date,
  required bool isCredit,
  List<String> tags = const [],
}) {
  return Transaction()
    ..amount = amount
    ..date = date
    ..isCredit = isCredit
    ..tags = List.of(tags)
    ..group = const []
    ..party = 'Test'
    ..note = null;
}

void main() {
  group('AnalyticsCubit', () {
    late FakeTransactionRepository repo;
    late AnalyticsCubit cubit;

    setUp(() {
      repo = FakeTransactionRepository();
      cubit = AnalyticsCubit(GetMonthlyAnalytics(repo));
    });

    tearDown(() => cubit.close());

    test('emits [InProgress, Success] with computed analytics', () async {
      repo.seed([
        _txn(amount: 120, date: DateTime(2026, 7, 5), isCredit: false, tags: ['food']),
        _txn(amount: 500, date: DateTime(2026, 7, 6), isCredit: true),
      ]);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AnalyticsLoadInProgress>(),
          isA<AnalyticsLoadSuccess>()
              .having((s) => s.analytics.totalOutflow, 'totalOutflow', 120)
              .having((s) => s.analytics.totalInflow, 'totalInflow', 500)
              .having((s) => s.analytics.tagSlices.first.label, 'topTag', 'food'),
        ]),
      );

      await cubit.loadAnalytics(DateTime(2026, 7));
      await expectation;
    });
  });
}
