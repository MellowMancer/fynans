import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';

import '../fakes/fake_transaction_repository.dart';
import '../support/builders.dart';

/// One month with every kind. Spending is 15,000 + 450 + 2,000 - 500 =
/// 16,950. Income is 62,000. Both legs of the repayment and of the transfer
/// count as neither.
List<Transaction> _month() => [
      aTransaction(
        kind: TransactionKind.income,
        amount: 62000,
        isInflow: true,
        date: DateTime(2026, 3, 1),
      ),
      aTransaction(
        kind: TransactionKind.expense,
        amount: 15000,
        date: DateTime(2026, 3, 2),
        tags: ['rent'],
      ),
      aTransaction(
        kind: TransactionKind.debt,
        amount: 450,
        date: DateTime(2026, 3, 3),
        tags: ['food'],
      ),
      aTransaction(
        kind: TransactionKind.debt,
        amount: 2000,
        date: DateTime(2026, 3, 9),
        tags: ['shopping'],
      ),
      aTransaction(
        kind: TransactionKind.refund,
        amount: 500,
        isInflow: true,
        date: DateTime(2026, 3, 9),
        tags: ['shopping'],
      ),
      aTransaction(
        kind: TransactionKind.repayment,
        amount: 8000,
        isInflow: false,
        date: DateTime(2026, 3, 5),
      ),
      aTransaction(
        kind: TransactionKind.repayment,
        amount: 8000,
        isInflow: true,
        date: DateTime(2026, 3, 5),
      ),
      aTransaction(
        kind: TransactionKind.transfer,
        amount: 5000,
        isInflow: false,
        date: DateTime(2026, 3, 6),
      ),
      aTransaction(
        kind: TransactionKind.transfer,
        amount: 5000,
        isInflow: true,
        date: DateTime(2026, 3, 6),
      ),
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
      aTransaction(
        kind: TransactionKind.debt,
        amount: 300,
        date: DateTime(2026, 3, 1),
        tags: ['gift'],
      ),
      aTransaction(
        kind: TransactionKind.refund,
        amount: 300,
        isInflow: true,
        date: DateTime(2026, 3, 2),
        tags: ['gift'],
      ),
      aTransaction(
        kind: TransactionKind.expense,
        amount: 100,
        date: DateTime(2026, 3, 3),
        tags: ['food'],
      ),
    ], 3);

    expect(analytics.tagSlices.map((s) => s.label), ['food']);
    expect(analytics.totalSpending, 100);
  });
}
