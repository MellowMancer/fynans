import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_cubit.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_state.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';

import '../../fakes/fake_transaction_repository.dart';
import '../../support/builders.dart';

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
        aTransaction(amount: 120, date: DateTime(2026, 7, 5), tags: ['food']),
        aTransaction(amount: 500, date: DateTime(2026, 7, 6), isInflow: true),
      ]);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AnalyticsLoadInProgress>(),
          isA<AnalyticsLoadSuccess>()
              .having((s) => s.analytics.totalSpending, 'totalSpending', 120)
              .having((s) => s.analytics.totalIncome, 'totalIncome', 500)
              .having(
                  (s) => s.analytics.tagSlices.first.label, 'topTag', 'food'),
        ]),
      );

      await cubit.loadAnalytics(DateTime(2026, 7));
      await expectation;
    });
  });
}
