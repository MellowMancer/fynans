import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/grouping_option.dart';
import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/widgets/month_year_wheel_picker.dart';
import 'package:fynans/ui/widgets/transaction_list_widgets.dart';
import 'package:fynans/use_cases/build_transaction_hierarchy.dart';

Transaction _txn(DateTime date, {double amount = 10}) => Transaction()
  ..amount = amount
  ..date = date
  ..tags = <String>[]
  ..group = <String>[]
  ..party = 'x'
  ..isCredit = false;

void main() {
  group('time buckets are chronological, not ranked by total', () {
    const build = BuildTransactionHierarchy();

    test('days list newest first regardless of amount', () {
      final nodes = build([
        _txn(DateTime(2026, 7, 3), amount: 900),   // biggest, oldest
        _txn(DateTime(2026, 7, 19), amount: 5),    // smallest, newest
        _txn(DateTime(2026, 7, 8), amount: 100),
      ], [GroupingOption.day]);

      expect(
        nodes.map((n) => n.name).toList(),
        ['19 Jul 2026', '8 Jul 2026', '3 Jul 2026'],
      );
    });

    test('weeks and months are chronological too', () {
      for (final option in [GroupingOption.week, GroupingOption.month]) {
        final nodes = build([
          _txn(DateTime(2026, 5, 4), amount: 900),
          _txn(DateTime(2026, 7, 20), amount: 5),
        ], [option]);
        expect(nodes.first.name.contains('Jul'), isTrue,
            reason: '$option should put the newest bucket first');
      }
    });

    test('non-time groupings still rank by total', () {
      final big = _txn(DateTime(2026, 7, 1), amount: 500)..group = ['Big'];
      final small = _txn(DateTime(2026, 7, 9), amount: 5)..group = ['Small'];
      final nodes = build([small, big], [GroupingOption.group]);

      // total = income - expenses, so the *smallest* expense ranks highest.
      expect(nodes.first.name, 'Small');
    });

    test('only day/week/month are chronological', () {
      expect(GroupingOption.day.isChronological, isTrue);
      expect(GroupingOption.week.isChronological, isTrue);
      expect(GroupingOption.month.isChronological, isTrue);
      expect(GroupingOption.group.isChronological, isFalse);
      expect(GroupingOption.tag.isChronological, isFalse);
      expect(GroupingOption.party.isChronological, isFalse);
    });
  });

  group('month wheel clamps to the declared range', () {
    testWidgets('a month past lastDate is clamped back', (tester) async {
      final emitted = <DateTime>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: MonthYearWheelPicker(
                initialDate: DateTime(2026, 7),
                firstDate: DateTime(2021, 7),
                lastDate: DateTime(2026, 7),
                onChanged: emitted.add,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<MonthYearWheelPickerState>(
        find.byType(MonthYearWheelPicker),
      );
      // Simulate scrolling the month wheel to December of the final year.
      state.debugSelect(monthIndex: 11, yearIndex: 5);
      await tester.pump();

      expect(emitted.last, DateTime(2026, 7),
          reason: 'December 2026 is past lastDate and must clamp');
    });

    testWidgets('a month before firstDate is clamped forward', (tester) async {
      final emitted = <DateTime>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: MonthYearWheelPicker(
                initialDate: DateTime(2026, 7),
                firstDate: DateTime(2021, 7),
                lastDate: DateTime(2026, 7),
                onChanged: emitted.add,
              ),
            ),
          ),
        ),
      );

      tester
          .state<MonthYearWheelPickerState>(find.byType(MonthYearWheelPicker))
          .debugSelect(monthIndex: 0, yearIndex: 0); // Jan 2021
      await tester.pump();

      expect(emitted.last, DateTime(2021, 7));
    });
  });

  group('SummaryCard', () {
    testWidgets('fits the max top-N shape without overflow', (tester) async {
      const summary = MonthlySummary(
        total: -6500,
        totalIncome: 5000,
        totalExpenses: 11500,
        topTags: {'food': 4000, 'travel': 2500, 'groceries': 1200},
        topGroups: {'goa trip': 2500, 'office': 900, 'home': 400},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              // The height the month pager actually gives it.
              height: 360,
              child: SummaryBody(summary: summary),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull,
          reason: 'the body sizes to its content, so it must never overflow');
    });

    testWidgets('shows its own month while the figures are still loading',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 360,
              child: Column(
                children: [
                  StatementPeriodRow(
                    month: DateTime(2026, 6),
                    onSelectMonth: () {},
                  ),
                  const SummaryBody(summary: null),
                ],
              ),
            ),
          ),
        ),
      );

      // The row always shows its own month; the body loads separately.
      expect(find.text('Jun 2026'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TransactionTotals disclosure', () {
    const summary = MonthlySummary(
      total: -1500,
      totalIncome: 5000,
      totalExpenses: 6500,
      topTags: {'food': 4000, 'travel': 2500, 'groceries': 1200},
      topGroups: {'goa trip': 2500, 'office': 900, 'home': 400},
    );

    Widget host(Widget child) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(width: 400, height: 360, child: child),
          ),
        );

    testWidgets('the split is hidden until the net figure is tapped',
        (tester) async {
      await tester.pumpWidget(host(
        const SummaryBody(summary: summary),
      ));

      expect(find.text('INFLOW'), findsNothing);
      expect(find.text('OUTFLOW'), findsNothing);
      expect(find.text('NET FOR THIS PERIOD'), findsOneWidget);

      await tester.tap(find.text('NET FOR THIS PERIOD'));
      await tester.pumpAndSettle();

      expect(find.text('INFLOW'), findsOneWidget);
      expect(find.text('OUTFLOW'), findsOneWidget);
      // Expanding must still fit the fixed-height month pager.
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('NET FOR THIS PERIOD'));
      await tester.pumpAndSettle();
      expect(find.text('INFLOW'), findsNothing);
    });

    testWidgets('can start expanded', (tester) async {
      await tester.pumpWidget(
        host(const TransactionTotals(
          summary: summary,
          initiallyExpanded: true,
        )),
      );

      expect(find.text('INFLOW'), findsOneWidget);
      expect(find.text('OUTFLOW'), findsOneWidget);
    });
  });
}
