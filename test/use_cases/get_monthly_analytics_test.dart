import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';

import '../fakes/fake_transaction_repository.dart';
import '../support/builders.dart';

void main() {
  group('GetMonthlyAnalytics', () {
    late FakeTransactionRepository repo;
    late GetMonthlyAnalytics getMonthlyAnalytics;

    setUp(() {
      repo = FakeTransactionRepository();
      getMonthlyAnalytics = GetMonthlyAnalytics(repo);
    });

    test('computes inflow/outflow and daily spending for the month', () async {
      repo.seed([
        aTransaction(amount: 120, date: DateTime(2026, 7, 5), tags: ['food']),
        aTransaction(amount: 30, date: DateTime(2026, 7, 5), tags: ['food']),
        aTransaction(amount: 500, date: DateTime(2026, 7, 6), isInflow: true),
        aTransaction(amount: 999, date: DateTime(2026, 6, 30), tags: ['rent']),
      ]);

      final analytics = await getMonthlyAnalytics(DateTime(2026, 7));

      expect(analytics.totalSpending, 150);
      expect(analytics.totalIncome, 500);
      expect(analytics.dailySpending[5], 150);
      expect(analytics.dailySpending.containsKey(30), isFalse);
    });

    test('folds the 6th+ tags into an "Others" bucket', () async {
      repo.seed([
        aTransaction(amount: 60, date: DateTime(2026, 7, 1), tags: ['a']),
        aTransaction(amount: 50, date: DateTime(2026, 7, 2), tags: ['b']),
        aTransaction(amount: 40, date: DateTime(2026, 7, 3), tags: ['c']),
        aTransaction(amount: 30, date: DateTime(2026, 7, 4), tags: ['d']),
        aTransaction(amount: 20, date: DateTime(2026, 7, 5), tags: ['e']),
        aTransaction(amount: 8, date: DateTime(2026, 7, 6), tags: ['f']),
        aTransaction(amount: 2, date: DateTime(2026, 7, 7), tags: ['g']),
      ]);

      final analytics = await getMonthlyAnalytics(DateTime(2026, 7));

      // Top 5 individual tags + one "Others" slice.
      expect(analytics.tagSlices, hasLength(kAnalyticsTopN + 1));
      final labels = analytics.tagSlices.map((s) => s.label).toList();
      expect(labels, ['a', 'b', 'c', 'd', 'e', kOthersSliceLabel]);

      final others = analytics.tagSlices.last;
      // f (8) + g (2) folded together.
      expect(others.amount, 10);
    });

    test('computes per-slice percentages of total outflow', () async {
      repo.seed([
        aTransaction(amount: 75, date: DateTime(2026, 7, 1), tags: ['food']),
        aTransaction(amount: 25, date: DateTime(2026, 7, 2), tags: ['travel']),
      ]);

      final analytics = await getMonthlyAnalytics(DateTime(2026, 7));

      final food = analytics.tagSlices.firstWhere((s) => s.label == 'food');
      final travel = analytics.tagSlices.firstWhere((s) => s.label == 'travel');
      expect(food.percentage, 75);
      expect(travel.percentage, 25);
    });

    test('guards divide-by-zero: no NaN percentages when outflow is 0',
        () async {
      // Only credit transactions -> zero outflow.
      repo.seed([
        aTransaction(amount: 500, date: DateTime(2026, 7, 6), isInflow: true),
      ]);

      final analytics = await getMonthlyAnalytics(DateTime(2026, 7));

      expect(analytics.totalSpending, 0);
      expect(analytics.tagSlices, isEmpty);
      for (final slice in analytics.tagSlices) {
        expect(slice.percentage.isNaN, isFalse);
      }
    });
  });
}
