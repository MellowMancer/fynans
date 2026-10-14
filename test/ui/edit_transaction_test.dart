import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';

import '../fakes/fake_transaction_repository.dart';

/// The add-transaction form in edit mode.
void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());
  tearDown(() => repository.dispose());

  Future<Transaction> seed({String? smsId}) async {
    final t = Transaction()
      ..amount = 410
      ..date = DateTime.now()
      ..tags = ['food']
      ..party = 'Cafe'
      ..isInflow = false
      ..smsId = smsId;
    await repository.saveTransaction(t);
    return t;
  }

  /// Opens the form on top of a home page, so that a save can close it.
  Future<void> openEditor(WidgetTester tester, Transaction editing) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<TransactionRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(editing: editing)),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String text) =>
      find.ancestor(of: find.text(text), matching: find.byType(TextField));

  testWidgets('opens filled in, and saving updates the row', (tester) async {
    final existing = await seed();
    await openEditor(tester, existing);

    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('410.00'), findsOneWidget);

    await tester.enterText(field('Cafe'), 'Bakery');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit transaction'), findsNothing,
        reason: 'the form closes after the save');
    final rows = await repository.fetchTransactionsInRange(
        range: DateRange.month(DateTime.now()));
    expect(rows.single.id, existing.id);
    expect(rows.single.party, 'Bakery');
  });

  testWidgets('locks the amount of an SMS row and says why', (tester) async {
    await openEditor(tester, await seed(smsId: 'sms-1'));

    expect(find.textContaining('From the SMS'), findsOneWidget);
    final amount = tester.widget<TextField>(field('410.00'));
    expect(amount.readOnly, isTrue);
  });
}
