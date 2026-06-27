import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/widgets/transaction_list_item.dart';

/// Phase 3: a transaction carrying a scam-risk score shows a warning badge in
/// the Expenses list; a clean transaction shows none.
Transaction _tx({int? scamScore}) => Transaction()
  ..amount = 5000
  ..date = DateTime(2026, 6, 27)
  ..tags = ['shopping']
  ..group = []
  ..party = 'Test Merchant'
  ..isCredit = false
  ..scamScore = scamScore;

Future<void> _pump(WidgetTester tester, Transaction t) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TransactionListItem(transaction: t))),
    );

void main() {
  testWidgets('high score shows "Likely scam" badge', (tester) async {
    await _pump(tester, _tx(scamScore: 86));
    expect(find.textContaining('Likely scam'), findsOneWidget);
    expect(find.textContaining('86/100'), findsOneWidget);
  });

  testWidgets('medium score shows "Suspicious" badge', (tester) async {
    await _pump(tester, _tx(scamScore: 30));
    expect(find.textContaining('Suspicious'), findsOneWidget);
  });

  testWidgets('no score shows no badge', (tester) async {
    await _pump(tester, _tx(scamScore: null));
    expect(find.textContaining('scam'), findsNothing);
    expect(find.textContaining('Suspicious'), findsNothing);
  });

  testWidgets('low score (<25) shows no badge', (tester) async {
    await _pump(tester, _tx(scamScore: 10));
    expect(find.textContaining('Suspicious'), findsNothing);
    expect(find.textContaining('Likely scam'), findsNothing);
  });
}
