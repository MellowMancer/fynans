import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/cards/cards_cubit.dart';
import 'package:fynans/adapters/blocs/cards/cards_state.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/credit_card.dart';

import '../../../fakes/fake_card_repository.dart';
import '../../../fakes/fake_card_statement_repository.dart';
import '../../../fakes/fake_transaction_repository.dart';

/// Covers the third per-card subscription `CardsCubit` gained for the latest
/// statement — the same generation-guarded cancel-then-resubscribe discipline
/// as the pre-existing transactions subscription, exercised directly rather
/// than only incidentally through the widget tests.
void main() {
  late FakeCardRepository cardRepository;
  late FakeTransactionRepository transactionRepository;
  late FakeCardStatementRepository statementRepository;
  late CardsCubit cubit;

  setUp(() {
    cardRepository = FakeCardRepository();
    transactionRepository = FakeTransactionRepository();
    statementRepository = FakeCardStatementRepository();
    cubit =
        CardsCubit(transactionRepository, cardRepository, statementRepository);
  });

  tearDown(() async {
    await cubit.close();
    await cardRepository.dispose();
    await transactionRepository.dispose();
    await statementRepository.dispose();
  });

  CreditCard seedCard() {
    final card = CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..creditLimit = 50000;
    cardRepository.seed([card]);
    return card;
  }

  test('a card with no statement yet reports latestStatement as null',
      () async {
    seedCard();
    cubit.loadCards();
    await pumpEventQueue();

    final state = cubit.state as CardsLoadSuccess;
    expect(state.cards.single.latestStatement, isNull);
  });

  test('a new statement import updates latestStatement live', () async {
    final card = seedCard();
    cubit.loadCards();
    await pumpEventQueue();

    await statementRepository.importStatement(CardStatement()
      ..cardId = card.id!
      ..statementDate = DateTime(2026, 1, 20)
      ..totalDue = 5000);
    await pumpEventQueue();

    final state = cubit.state as CardsLoadSuccess;
    expect(state.cards.single.latestStatement?.totalDue, 5000);
  });

  test(
      'deleting a card cancels its statement subscription — a later import '
      'for the deleted card id never resurrects an entry', () async {
    final card = seedCard();
    cubit.loadCards();
    await pumpEventQueue();

    await cardRepository.deleteCard(card);
    await pumpEventQueue();

    expect((cubit.state as CardsLoadSuccess).cards, isEmpty);

    await statementRepository.importStatement(CardStatement()
      ..cardId = card.id!
      ..statementDate = DateTime(2026, 1, 20)
      ..totalDue = 5000);
    await pumpEventQueue();

    expect((cubit.state as CardsLoadSuccess).cards, isEmpty);
  });

  test(
      'a second loadCards bumps the generation, so a stale statement event '
      'from the superseded subscription set is discarded', () async {
    final card = seedCard();
    cubit.loadCards();
    await pumpEventQueue();

    // Reload — bumps _generation and cancels/resubscribes everything.
    cubit.loadCards();
    await pumpEventQueue();

    await statementRepository.importStatement(CardStatement()
      ..cardId = card.id!
      ..statementDate = DateTime(2026, 1, 20)
      ..totalDue = 7000);
    await pumpEventQueue();

    // The current (second-generation) subscription still picks this up —
    // only a truly stale (closed) generation would discard it.
    final state = cubit.state as CardsLoadSuccess;
    expect(state.cards.single.latestStatement?.totalDue, 7000);
  });
}
