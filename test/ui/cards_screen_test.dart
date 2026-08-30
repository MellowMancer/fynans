import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_card_screen.dart';
import 'package:fynans/ui/screens/card_detail_screen.dart';
import 'package:fynans/ui/screens/cards_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';

import '../fakes/fake_card_repository.dart';
import '../fakes/fake_detected_card_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository transactionRepository;
  late FakeCardRepository cardRepository;
  late FakeDetectedCardRepository detectedCardRepository;

  setUp(() {
    transactionRepository = FakeTransactionRepository();
    cardRepository = FakeCardRepository();
    detectedCardRepository = FakeDetectedCardRepository();
  });

  tearDown(() async {
    await transactionRepository.dispose();
    await cardRepository.dispose();
    await detectedCardRepository.dispose();
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
      CreditCard()
        ..issuer = 'HDFC'
        ..last4 = '1234'
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
    final card = CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..creditLimit = 50000;
    cardRepository.seed([card]);
    transactionRepository.seed([
      Transaction()
        ..amount = 259
        ..date = DateTime(2026, 1, 15)
        ..tags = []
        ..group = []
        ..party = 'Merchant'
        ..isCredit = false
        ..cardId = card.id,
    ]);

    await pumpScreen(tester);

    // 50000 - 259 = 49741 available; the tile shows both figures somewhere.
    expect(find.textContaining('49,741', findRichText: true), findsWidgets);
  });

  testWidgets('the add-card FAB opens AddCardScreen', (tester) async {
    cardRepository.seed([
      CreditCard()
        ..issuer = 'HDFC'
        ..last4 = '1234'
        ..creditLimit = 50000,
    ]);

    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddCardScreen), findsOneWidget);
  });

  testWidgets('tapping a card tile opens its detail screen', (tester) async {
    final card = CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
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
}
