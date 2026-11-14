import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';

import '../fakes/fake_transaction_repository.dart';

/// The extra kinds stay collapsed under "More", and a picked kind is saved.
void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());
  tearDown(() => repository.dispose());

  Future<void> pumpForm(WidgetTester tester) async {
    // Tall enough for the whole form, so that no tap needs a scroll.
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<TransactionRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AddTransactionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSave(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, '250');
    await tapText(tester, 'Choose one or more tags');
    await tapText(tester, 'Food');
    await tapText(tester, 'Done');
    final partyHint = find.textContaining(RegExp('Who (paid you|did you pay)'));
    await tester.enterText(
        find.ancestor(of: partyHint, matching: find.byType(TextField)),
        'Savings');
    await tapText(tester, 'Save transaction');
  }

  Future<Transaction> savedRow() async => (await repository
          .fetchTransactionsInRange(range: DateRange.month(DateTime.now())))
      .single;

  testWidgets('the extra kinds are hidden until "More" is tapped',
      (tester) async {
    await pumpForm(tester);
    expect(find.text('Transfer'), findsNothing);

    await tapText(tester, 'More');

    for (final label in ['Debt', 'Refund', 'Repayment', 'Transfer']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('a picked transfer is saved with the chosen direction',
      (tester) async {
    await pumpForm(tester);
    await tapText(tester, 'More');
    await tapText(tester, 'Transfer');
    await tapText(tester, 'Inflow');

    await fillAndSave(tester);

    final row = await savedRow();
    expect(row.kind, TransactionKind.transfer);
    expect(row.isInflow, isTrue);
  });

  testWidgets('a direction that does not fit the picked kind clears it',
      (tester) async {
    await pumpForm(tester);
    await tapText(tester, 'More');
    await tapText(tester, 'Refund');
    await tapText(tester, 'Outflow');

    await fillAndSave(tester);

    final row = await savedRow();
    expect(row.kind, TransactionKind.expense,
        reason: 'a refund cannot be money out, so the form dropped it');
    expect(row.isInflow, isFalse);
  });
}
