import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_card_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';

import '../fakes/fake_card_repository.dart';
import '../fakes/fake_card_statement_repository.dart';
import '../fakes/fake_detected_card_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  const limitLabel = 'CREDIT LIMIT';
  const accountLabel = 'BANK ACCOUNT LAST 3-4 DIGITS (OPTIONAL)';

  testWidgets('the debit type shows the account field instead of the limit',
      (tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CardRepository>.value(
              value: FakeCardRepository()),
          RepositoryProvider<TransactionRepository>.value(
              value: FakeTransactionRepository()),
          RepositoryProvider<DetectedCardRepository>.value(
              value: FakeDetectedCardRepository()),
          RepositoryProvider<CardStatementRepository>.value(
              value: FakeCardStatementRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AddCardScreen(),
        ),
      ),
    );

    expect(find.text(limitLabel), findsOneWidget);
    expect(find.text(accountLabel), findsNothing);

    await tester.tap(find.text('Debit'));
    await tester.pumpAndSettle();

    expect(find.text(limitLabel), findsNothing);
    expect(find.text(accountLabel), findsOneWidget);
  });
}
