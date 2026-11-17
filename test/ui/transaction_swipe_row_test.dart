import 'package:flutter/material.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:flutter/rendering.dart';
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

/// Sliding a row shows Edit, Delete and Cancel, and Delete asks first.
void main() {
  late FakeTransactionRepository repository;
  late Transaction row;

  setUp(() async {
    repository = FakeTransactionRepository();
    row = Transaction()
      ..amount = 410
      ..date = DateTime.now()
      ..tags = ['food']
      ..party = 'Cafe'
      ..isInflow = false
      ..kind = TransactionKind.expense;
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

  // The card's visible box, without the gap below the row.
  Finder card() => find
      .descendant(
          of: find.byType(TransactionListItem),
          matching: find.byType(DecoratedBox))
      .first;

  /// The fill under the card's rounded right corners.
  Finder cornerFill() => find.descendant(
      of: find
          .byWidgetPredicate((w) => w is Positioned && w.width == AppRadius.lg),
      matching: find.byType(ColoredBox));

  testWidgets('the buttons are as tall as the card', (tester) async {
    await pumpRow(tester);
    await slideOpen(tester);

    expect(tester.getSize(find.byType(SlidableAction).first).height,
        tester.getSize(card()).height);
  });

  testWidgets('the card slides off the screen edge, not into the gutter',
      (tester) async {
    await pumpRow(tester);

    expect(tester.getRect(card()).left, AppSpacing.gutter,
        reason: 'at rest the card keeps its place in the page');
    expect(tester.getRect(find.byType(Slidable)).left, 0,
        reason: 'the slide area reaches the screen edge, so nothing clips '
            'the card at the gutter');
  });

  testWidgets('the right end of the buttons has the card\'s corners',
      (tester) async {
    await pumpRow(tester);
    await slideOpen(tester);

    final cancel = tester.widget<SlidableAction>(find.ancestor(
        of: find.byIcon(Icons.close_rounded),
        matching: find.byType(SlidableAction)));
    expect(cancel.borderRadius,
        const BorderRadius.horizontal(right: Radius.circular(AppRadius.lg)));
  });

  testWidgets('the card\'s corners rest on the Edit colour only while open',
      (tester) async {
    await pumpRow(tester);
    expect(cornerFill(), findsNothing,
        reason: 'at rest it would show in the card\'s corners');

    await slideOpen(tester);

    final fill = tester.getRect(cornerFill());
    expect(fill.right, moreOrLessEquals(tester.getRect(card()).right),
        reason: 'the fill lies under the card\'s right edge');
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

  group('the delete dialog shows the amount large, in its direction colour',
      () {
    Future<MoneyText> amountIn(WidgetTester tester) async {
      await pumpRow(tester);
      await slideOpen(tester);
      await tap(tester, find.byIcon(Icons.delete_outline_rounded));
      return tester.widget<MoneyText>(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(MoneyText)));
    }

    double fontSizeOf(WidgetTester tester, Finder text) =>
        tester.renderObject<RenderParagraph>(text).text.style!.fontSize!;

    testWidgets('red for money out, larger than the other lines',
        (tester) async {
      final amount = await amountIn(tester);

      expect(amount.tone, MoneyTone.negative);
      final amountText = find.descendant(
          of: find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(MoneyText)),
          matching: find.byType(RichText));
      final partyText = find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Cafe'));
      expect(fontSizeOf(tester, amountText.first),
          greaterThan(fontSizeOf(tester, partyText)));
    });

    testWidgets('green for money in', (tester) async {
      row
        ..isInflow = true
        ..kind = TransactionKind.income;
      expect((await amountIn(tester)).tone, MoneyTone.positive);
    });
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
