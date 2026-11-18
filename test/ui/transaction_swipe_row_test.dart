import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/widgets/transaction_list_widgets.dart';
import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/entities/hierarchy_node.dart';
import 'package:fynans/ui/widgets/transaction_list_item.dart';
import 'package:fynans/ui/widgets/transaction_swipe_row.dart';

import '../fakes/fake_transaction_repository.dart';
import '../support/builders.dart';

/// Sliding a row shows Edit, Delete and Cancel, and Delete asks first.
void main() {
  late FakeTransactionRepository repository;
  late Transaction row;

  setUp(() async {
    repository = FakeTransactionRepository();
    row = aTransaction(
      amount: 410,
      date: DateTime.now(),
      tags: ['food'],
      party: 'Cafe',
    );
    await repository.saveTransaction(row);
  });
  tearDown(() => repository.dispose());

  Future<void> pumpRow(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<TransactionRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SlidableAutoCloseBehavior(
              // The real list's padding: no left gutter for the rows.
              child: ListView(
                padding: AppSpacing.pageInsets.copyWith(left: 0),
                children: [TransactionSwipeRow(transaction: row)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> slideOpen(WidgetTester tester) async {
    await tester.drag(find.byType(TransactionListItem), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<List<Transaction>> stored() => repository.fetchTransactionsInRange(
      range: DateRange.month(DateTime.now()));

  testWidgets('a slide stops open with three buttons, not a delete',
      (tester) async {
    await pumpRow(tester);
    await slideOpen(tester);

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byType(TransactionListItem), findsOneWidget);
    expect(await stored(), hasLength(1));
  });
  testWidgets('Cancel closes the row', (tester) async {
    await pumpRow(tester);
    await slideOpen(tester);

    await tap(tester, find.byIcon(Icons.close_rounded));

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(await stored(), hasLength(1));
  });

  testWidgets('Delete asks first; Cancel in the dialog keeps the row',
      (tester) async {
    await pumpRow(tester);
    await slideOpen(tester);

    await tap(tester, find.byIcon(Icons.delete_outline_rounded));
    expect(find.text('Delete this transaction?'), findsOneWidget);

    await tap(
        tester,
        find.descendant(
            of: find.byType(AlertDialog), matching: find.text('Cancel')));

    expect(find.byType(AlertDialog), findsNothing);
    expect(await stored(), hasLength(1));
  });

  testWidgets('Delete in the dialog deletes the row', (tester) async {
    await pumpRow(tester);
    await slideOpen(tester);
    await tap(tester, find.byIcon(Icons.delete_outline_rounded));

    await tap(
        tester,
        find.descendant(
            of: find.byType(AlertDialog), matching: find.text('Delete')));

    expect(await stored(), isEmpty);
  });

  testWidgets('Edit opens the form in edit mode', (tester) async {
    await pumpRow(tester);
    await slideOpen(tester);

    await tap(tester, find.byIcon(Icons.edit_outlined));

    expect(find.text('Edit transaction'), findsOneWidget);
  });

  testWidgets('the advanced view\'s rows slide too, inside their group card',
      (tester) async {
    const summary = MonthlySummary(
        total: -410,
        totalIncome: 0,
        totalExpenses: 410,
        topTags: {},
        topGroups: {});
    await tester.pumpWidget(
      RepositoryProvider<TransactionRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: HierarchicalTransactionList(
              summary: summary,
              nodes: [
                HierarchyNode(
                  name: 'food',
                  summary: summary,
                  transactionCount: 1,
                  transactions: [row],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('Food'));

    await slideOpen(tester);

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
