import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';

import '../fakes/fake_transaction_repository.dart';

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
  group('GetMonthlyAnalytics', () {
    late FakeTransactionRepository repo;
    late GetMonthlyAnalytics getMonthlyAnalytics;

    setUp(() {
      repo = FakeTransactionRepository();
      getMonthlyAnalytics = GetMonthlyAnalytics(repo);
    });

    test('computes inflow/outflow and daily spending for the month', () async {
      repo.seed([
        _txn(amount: 120, date: DateTime(2026, 7, 5), isCredit: false, tags: ['food']),
        _txn(amount: 30, date: DateTime(2026, 7, 5), isCredit: false, tags: ['food']),
        _txn(amount: 500, date: DateTime(2026, 7, 6), isCredit: true),
        _txn(amount: 999, date: DateTime(2026, 6, 30), isCredit: false, tags: ['rent']),
      ]);

      final analytics = await getMonthlyAnalytics(DateTime(2026, 7));

      expect(analytics.totalOutflow, 150);
      expect(analytics.totalInflow, 500);
      expect(analytics.dailySpending[5], 150);
      expect(analytics.dailySpending.containsKey(30), isFalse);
    });

    test('folds the 6th+ tags into an "Others" bucket', () async {
      repo.seed([
        _txn(amount: 60, date: DateTime(2026, 7, 1), isCredit: false, tags: ['a']),
        _txn(amount: 50, date: DateTime(2026, 7, 2), isCredit: false, tags: ['b']),
        _txn(amount: 40, date: DateTime(2026, 7, 3), isCredit: false, tags: ['c']),
        _txn(amount: 30, date: DateTime(2026, 7, 4), isCredit: false, tags: ['d']),
        _txn(amount: 20, date: DateTime(2026, 7, 5), isCredit: false, tags: ['e']),
        _txn(amount: 8, date: DateTime(2026, 7, 6), isCredit: false, tags: ['f']),
        _txn(amount: 2, date: DateTime(2026, 7, 7), isCredit: false, tags: ['g']),
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
        _txn(amount: 75, date: DateTime(2026, 7, 1), isCredit: false, tags: ['food']),
        _txn(amount: 25, date: DateTime(2026, 7, 2), isCredit: false, tags: ['travel']),
      ]);

      final analytics = await getMonthlyAnalytics(DateTime(2026, 7));

      final food = analytics.tagSlices.firstWhere((s) => s.label == 'food');
      final travel = analytics.tagSlices.firstWhere((s) => s.label == 'travel');
      expect(food.percentage, 75);
      expect(travel.percentage, 25);
    });

    test('guards divide-by-zero: no NaN percentages when outflow is 0', () async {
      // Only credit transactions -> zero outflow. A defensive tag on a credit
      // must not produce a NaN percentage.
      repo.seed([
        _txn(amount: 500, date: DateTime(2026, 7, 6), isCredit: true),
      ]);

      final analytics = await getMonthlyAnalytics(DateTime(2026, 7));

      expect(analytics.totalOutflow, 0);
      expect(analytics.tagSlices, isEmpty);
      for (final slice in analytics.tagSlices) {
        expect(slice.percentage.isNaN, isFalse);
      }
    });
  });
}
