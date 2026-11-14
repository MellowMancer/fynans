import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_card_screen.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/screens/cards_screen.dart';
import 'package:fynans/ui/screens/transactions_list_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';

import '../fakes/fake_card_repository.dart';
import '../fakes/fake_card_statement_repository.dart';
import '../fakes/fake_detected_card_repository.dart';
import '../fakes/fake_transaction_repository.dart';

/// `MainScreen` keeps every tab alive in an [IndexedStack]. Two tabs have a
/// floating action button, and both stay in the tree. If the two buttons
/// share a hero tag, a push from either tab throws.
void main() {
  late FakeTransactionRepository transactions;
  late FakeCardRepository cards;
  late FakeDetectedCardRepository detected;
  late FakeCardStatementRepository statements;

  setUp(() {
    transactions = FakeTransactionRepository();
    cards = FakeCardRepository();
    detected = FakeDetectedCardRepository();
    statements = FakeCardStatementRepository();
  });

  Future<void> pumpTabs(WidgetTester tester, int index) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TransactionRepository>.value(value: transactions),
          RepositoryProvider<CardRepository>.value(value: cards),
          RepositoryProvider<DetectedCardRepository>.value(value: detected),
          RepositoryProvider<CardStatementRepository>.value(value: statements),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: IndexedStack(
              index: index,
              children: [
                MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) => TransactionCubit(transactions)),
                    BlocProvider(
                      create: (_) => AdvancedViewBloc(transactions)
                        ..add(AdvancedViewDataFetched()),
                    ),
                  ],
                  child: const TransactionsListScreen(),
                ),
                const CardsScreen(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the Expenses button opens its screen', (tester) async {
    await pumpTabs(tester, 0);

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AddTransactionScreen), findsOneWidget);
  });

  testWidgets('the Cards button opens its screen', (tester) async {
    await pumpTabs(tester, 1);

    await tester.tap(find.byTooltip('Add card'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AddCardScreen), findsOneWidget);
  });
}
