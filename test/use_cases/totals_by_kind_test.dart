import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';

import '../fakes/fake_transaction_repository.dart';

Transaction _row(
  TransactionKind kind,
  double amount, {
  required bool isInflow,
  required int day,
  List<String> tags = const [],
}) =>
    Transaction()
      ..amount = amount
      ..date = DateTime(2026, 3, day)
      ..tags = List<String>.of(tags)
      ..party = 'x'
      ..isInflow = isInflow
      ..kind = kind;

/// One month with every kind. Spending is 15,000 + 450 + 2,000 - 500 =
/// 16,950. Income is 62,000. Both legs of the repayment and of the transfer
/// count as neither.
List<Transaction> _month() => [
      _row(TransactionKind.income, 62000, isInflow: true, day: 1),
      _row(TransactionKind.expense, 15000,
          isInflow: false, day: 2, tags: ['rent']),
      _row(TransactionKind.debt, 450, isInflow: false, day: 3, tags: ['food']),
      _row(TransactionKind.debt, 2000,
          isInflow: false, day: 9, tags: ['shopping']),
      _row(TransactionKind.refund, 500,
          isInflow: true, day: 9, tags: ['shopping']),
      _row(TransactionKind.repayment, 8000, isInflow: false, day: 5),
      _row(TransactionKind.repayment, 8000, isInflow: true, day: 5),
      _row(TransactionKind.transfer, 5000, isInflow: false, day: 6),
      _row(TransactionKind.transfer, 5000, isInflow: true, day: 6),
    ];

void main() {
  test('the monthly summary counts spending and income by kind', () {
    final summary = summariseTransactions(_month());

    expect(summary.totalExpenses, 16950);
    expect(summary.totalIncome, 62000);
    expect(summary.total, 45050);
    expect(summary.topTags, {'rent': 15000, 'shopping': 1500, 'food': 450});
  });

  test('the analytics fold agrees with the monthly summary', () {
    final analytics = GetMonthlyAnalytics(FakeTransactionRepository())
        .aggregate(_month(), 3);

    expect(analytics.totalSpending, 16950);
    expect(analytics.totalIncome, 62000);
    expect(analytics.dailySpending, {2: 15000, 3: 450, 9: 1500});
    expect(
      {for (final s in analytics.tagSlices) s.label: s.amount},
      {'rent': 15000, 'shopping': 1500, 'food': 450},
    );
  });

  test('a tag that a refund takes to zero is not a pie slice', () {
    final analytics = GetMonthlyAnalytics(FakeTransactionRepository())
        .aggregate([
      _row(TransactionKind.debt, 300,
          isInflow: false, day: 1, tags: ['gift']),
      _row(TransactionKind.refund, 300, isInflow: true, day: 2, tags: ['gift']),
      _row(TransactionKind.expense, 100,
          isInflow: false, day: 3, tags: ['food']),
    ], 3);

    expect(analytics.tagSlices.map((s) => s.label), ['food']);
    expect(analytics.totalSpending, 100);
  });
}
