import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/cards/cards_cubit.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/card_detail_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/utils/formatters.dart';

import '../fakes/fake_card_repository.dart';
import '../fakes/fake_transaction_repository.dart';

Transaction spend(double amount, DateTime date, int cardId) => Transaction()
  ..amount = amount
  ..date = date
  ..tags = []
  ..group = []
  ..party = 'Merchant'
  ..isCredit = false
  ..cardId = cardId;

void main() {
  late FakeTransactionRepository transactionRepository;
  late FakeCardRepository cardRepository;
  late CreditCard card;

  setUp(() {
    transactionRepository = FakeTransactionRepository();
    cardRepository = FakeCardRepository();
    card = CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..creditLimit = 50000;
    cardRepository.seed([card]);
  });

  tearDown(() async {
    await transactionRepository.dispose();
    await cardRepository.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TransactionRepository>.value(
              value: transactionRepository),
          RepositoryProvider<CardRepository>.value(value: cardRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider(
            create: (context) => CardsCubit(
              context.read<TransactionRepository>(),
              context.read<CardRepository>(),
            )..loadCards(),
            child: CardDetailScreen(cardId: card.id!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'defaults to the current month: a transaction from a different month '
      'is excluded from the list, but the all-time summary still counts it',
      (tester) async {
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month, 1);
    transactionRepository.seed([
      spend(1000, DateTime(now.year, now.month, 5), card.id!),
      spend(4000, lastYear, card.id!),
    ]);

    await pumpScreen(tester);

    // All-time available = 50000 - (1000 + 4000) = 45000 — the CardTile
    // summary counts both, even though only one is in the visible month.
    expect(find.textContaining('45,000.00', findRichText: true), findsWidgets);

    // Only the current-month transaction's row renders in the list.
    expect(find.text('-${Fmt.money(1000)}'), findsOneWidget);
    expect(find.text('-${Fmt.money(4000)}'), findsNothing);
  });

  testWidgets('"Spent this month" reflects only the selected month',
      (tester) async {
    final now = DateTime.now();
    transactionRepository.seed([
      spend(300, DateTime(now.year, now.month, 3), card.id!),
      spend(700, DateTime(now.year, now.month, 10), card.id!),
      spend(9999, DateTime(now.year - 1, now.month, 1), card.id!),
    ]);

    await pumpScreen(tester);

    expect(find.text('SPENT THIS MONTH'), findsOneWidget);
    // 300 + 700 = 1000 this month; the 9999 from last year is excluded.
    expect(find.textContaining('1,000.00', findRichText: true), findsWidgets);
    expect(find.textContaining('9,999.00', findRichText: true), findsNothing);
  });

  testWidgets(
      'empty state distinguishes "no transactions this month" from '
      '"no transactions yet"', (tester) async {
    final now = DateTime.now();
    transactionRepository.seed([
      spend(500, DateTime(now.year - 1, now.month, 1), card.id!),
    ]);

    await pumpScreen(tester);

    expect(find.text('No transactions this month'), findsOneWidget);
    expect(find.text('No transactions yet'), findsNothing);
  });

  testWidgets('truly empty card shows "No transactions yet"', (tester) async {
    await pumpScreen(tester);

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('No transactions this month'), findsNothing);
  });

  testWidgets('tapping the month icon opens the month picker', (tester) async {
    // The wheel picker's sheet needs more height than the test default.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Change month'));
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsOneWidget);
  });
}
