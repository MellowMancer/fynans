import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_cubit.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_state.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';

import '../../fakes/fake_transaction_repository.dart';

Transaction _txn(double amount, DateTime date, {bool isCredit = false}) =>
    Transaction()
      ..amount = amount
      ..date = date
      ..tags = ['food']
      ..group = <String>[]
      ..party = 'x'
      ..isCredit = isCredit;

void main() {
  test('analytics recompute when transactions are written afterwards',
      () async {
    final repo = FakeTransactionRepository();
    final cubit = AnalyticsCubit(GetMonthlyAnalytics(repo));
    addTearDown(cubit.close);

    // The Analytics tab is built before the SMS sweep has imported anything.
    await cubit.loadAnalytics(DateTime(2026, 7));
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as AnalyticsLoadSuccess).analytics.totalOutflow, 0);

    final updated = expectLater(
      cubit.stream,
      emitsThrough(
        isA<AnalyticsLoadSuccess>()
            .having((s) => s.analytics.totalOutflow, 'totalOutflow', 250),
      ),
    );

    // The sweep imports; the tab must reflect it without re-picking the month.
    await repo.saveTransaction(_txn(250, DateTime(2026, 7, 5)));
    await updated;
  });
}
