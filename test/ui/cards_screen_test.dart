import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_card_screen.dart';
import 'package:fynans/ui/screens/card_detail_screen.dart';
import 'package:fynans/ui/screens/cards_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/utils/formatters.dart';

import '../fakes/fake_card_repository.dart';
import '../fakes/fake_card_statement_repository.dart';
import '../fakes/fake_detected_card_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository transactionRepository;
  late FakeCardRepository cardRepository;
  late FakeDetectedCardRepository detectedCardRepository;
  late FakeCardStatementRepository statementRepository;

  setUp(() {
    transactionRepository = FakeTransactionRepository();
    cardRepository = FakeCardRepository();
    detectedCardRepository = FakeDetectedCardRepository();
    statementRepository = FakeCardStatementRepository();
  });

  tearDown(() async {
    await transactionRepository.dispose();
    await cardRepository.dispose();
    await detectedCardRepository.dispose();
    await statementRepository.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        // Wraps MaterialApp itself, not `home:` — a pushed route (add card,
        // card detail) lives outside `home:`'s own subtree and needs the
        // providers to sit above the Navigator to see them, same as
        // main.dart's real composition root.
        providers: [
          RepositoryProvider<TransactionRepository>.value(
              value: transactionRepository),
          RepositoryProvider<CardRepository>.value(value: cardRepository),
          RepositoryProvider<DetectedCardRepository>.value(
              value: detectedCardRepository),
          RepositoryProvider<CardStatementRepository>.value(
              value: statementRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CardsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty state shown when no cards are registered', (tester) async {
    await pumpScreen(tester);

    expect(find.text('No cards yet'), findsOneWidget);
    expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget);
  });

  testWidgets('a registered card renders its tile with issuer and last4',
      (tester) async {
    cardRepository.seed([
      PaymentCard()
        ..issuer = 'HDFC'
        ..last4 = '1234'
        ..type = CardType.credit
        ..status = CardStatus.active
        ..creditLimit = 50000,
    ]);

    await pumpScreen(tester);

    expect(find.textContaining('HDFC', findRichText: true), findsWidgets);
    expect(find.textContaining('1234', findRichText: true), findsWidgets);
    expect(find.text('No cards yet'), findsNothing);
  });

  testWidgets(
      'a card with a matched transaction shows spent, not available equal to full limit',
      (tester) async {
    final card = PaymentCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..type = CardType.credit
      ..status = CardStatus.active
      ..creditLimit = 50000;
    cardRepository.seed([card]);
    transactionRepository.seed([
      Transaction()
        ..amount = 259
        ..date = DateTime(2026, 1, 15)
        ..tags = []
        ..group = []
        ..party = 'Merchant'
        ..isInflow = false
        ..kind = TransactionKind.expense
        ..cardId = card.id,
    ]);

    await pumpScreen(tester);

    // 50000 - 259 = 49741 available; the tile shows both figures somewhere.
    expect(find.textContaining('49,741', findRichText: true), findsWidgets);
  });

  testWidgets('the add-card FAB opens AddCardScreen', (tester) async {
    cardRepository.seed([
      PaymentCard()
        ..issuer = 'HDFC'
        ..last4 = '1234'
        ..type = CardType.credit
        ..status = CardStatus.active
        ..creditLimit = 50000,
    ]);

    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddCardScreen), findsOneWidget);
  });

  testWidgets('tapping a card tile opens its detail screen', (tester) async {
    final card = PaymentCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..type = CardType.credit
      ..status = CardStatus.active
      ..creditLimit = 50000;
    cardRepository.seed([card]);

    await pumpScreen(tester);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailScreen), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  group('DetectedCardsBanner', () {
    DetectedCard detection() => DetectedCard()
      ..issuerGuess = 'HDFC'
      ..sender = 'HDFCCC'
      ..last4 = '1234'
      ..firstSeen = DateTime(2026, 1, 1)
      ..lastSeen = DateTime(2026, 1, 5)
      ..sightingCount = 3;

    testWidgets('a pending sighting prompts even with zero registered cards',
        (tester) async {
      detectedCardRepository.seed([detection()]);

      await pumpScreen(tester);

      expect(find.textContaining('HDFC', findRichText: true), findsWidgets);
      expect(find.textContaining('1234', findRichText: true), findsWidgets);
      expect(find.text('No cards yet'), findsOneWidget,
          reason: 'the empty state below the banner is unaffected');
    });

    testWidgets('nothing renders when there is no pending sighting',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Not mine'), findsNothing);
      expect(find.text('Detected card'), findsNothing);
    });

    testWidgets('"Not mine" dismisses the sighting', (tester) async {
      detectedCardRepository.seed([detection()]);
      await pumpScreen(tester);

      await tester.tap(find.text('Not mine'));
      await tester.pumpAndSettle();

      expect(find.text('Not mine'), findsNothing);
      expect(detectedCardRepository.all.single.dismissed, isTrue);
    });

    testWidgets('"Add card" opens AddCardScreen pre-filled from the sighting',
        (tester) async {
      final d = detection();
      detectedCardRepository.seed([d]);
      await pumpScreen(tester);

      await tester.tap(find.text('Add card'));
      await tester.pumpAndSettle();

      expect(find.byType(AddCardScreen), findsOneWidget);
      final issuerField =
          tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(issuerField.controller!.text, 'HDFC');
    });
  });

  group('closed and untracked cards', () {
    PaymentCard closedCard() => PaymentCard()
      ..issuer = 'AXIS'
      ..last4 = '4321'
      ..type = CardType.credit
      ..status = CardStatus.closed
      ..closedOn = DateTime(2026, 7, 31)
      ..creditLimit = 50000;

    testWidgets('sit in a collapsed section that shows what they hide',
        (tester) async {
      final closed = closedCard();
      cardRepository.seed([
        PaymentCard()
          ..issuer = 'HDFC'
          ..last4 = '1234'
          ..type = CardType.credit
          ..status = CardStatus.active
          ..creditLimit = 50000,
        closed,
      ]);
      transactionRepository.seed([
        Transaction()
          ..amount = 300
          ..date = DateTime(2026, 8, 2)
          ..tags = <String>[]
          ..group = <String>[]
          ..party = 'x'
          ..isInflow = false
          ..kind = TransactionKind.debt
          ..cardId = closed.id,
      ]);
      await pumpScreen(tester);

      expect(find.text('CLOSED AND UNTRACKED (1)'), findsOneWidget);
      expect(find.textContaining('4321', findRichText: true), findsNothing,
          reason: 'the section starts collapsed');

      await tester.tap(find.text('CLOSED AND UNTRACKED (1)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('4321', findRichText: true), findsWidgets);
      expect(
        find.text('HIDES 1 TRANSACTION (${Fmt.money(300)})'),
        findsOneWidget,
      );
    });

    testWidgets('with no active card, the page shows the section, not the '
        'empty state', (tester) async {
      cardRepository.seed([closedCard()]);
      await pumpScreen(tester);

      expect(find.text('No cards yet'), findsNothing);
      expect(find.text('CLOSED AND UNTRACKED (1)'), findsOneWidget);
    });
  });
}
