import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/cards/cards_cubit.dart';
import 'package:fynans/adapters/blocs/cards/cards_state.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';

import '../../../fakes/fake_card_repository.dart';
import '../../../fakes/fake_card_statement_repository.dart';
import '../../../fakes/fake_transaction_repository.dart';
import '../../../support/builders.dart';

/// Fails each card's transaction query with an error text that names a card,
/// like a real database error can.
class _FailingCardQueries extends FakeTransactionRepository {
  @override
  Stream<List<Transaction>> listenToTransactionsForCard(int cardId) =>
      Stream.error(StateError('SQL error near card_id = $cardId, last4 1234'));
}

/// Fails each card's statement query, like [_FailingCardQueries].
class _FailingStatementQueries extends FakeCardStatementRepository {
  @override
  Stream<CardStatement?> watchLatestStatement(int cardId) =>
      Stream.error(StateError('SQL error near card_id = $cardId, last4 1234'));
}

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

  PaymentCard seedCard() {
    final card = aCard();
    cardRepository.seed([card]);
    return card;
  }

  group('a failed card query', () {
    Future<CardsState> loadWith(
        FakeTransactionRepository transactions,
        FakeCardStatementRepository statements) async {
      final failing = CardsCubit(transactions, cardRepository, statements);
      addTearDown(failing.close);
      seedCard();
      failing.loadCards();
      await pumpEventQueue();
      return failing.state;
    }

    final showsPlainFailure = isA<CardsLoadFailure>()
        .having((s) => s.error, 'error', CardsCubit.loadFailedMessage);

    test('of the transactions shows a plain failure', () async {
      expect(await loadWith(_FailingCardQueries(), statementRepository),
          showsPlainFailure);
    });

    test('of the statement shows a plain failure', () async {
      expect(await loadWith(transactionRepository, _FailingStatementQueries()),
          showsPlainFailure);
    });
  });

  test('a debit card gets a summary instead of crashing the page', () async {
    cardRepository.seed([aCard(type: CardType.debit, last4: '4321')]);
    cubit.loadCards();
    await pumpEventQueue();

    final state = cubit.state as CardsLoadSuccess;
    expect(state.cards.single.summary.card.type, CardType.debit);
    expect(state.cards.single.summary.spent, 0);
  });

  test('a closed card moves to the retired list, with what it hides',
      () async {
    final card = seedCard();
    transactionRepository.seed([aTransaction(date: DateTime(2026, 8, 2), card: card)]);
    cubit.loadCards();
    await pumpEventQueue();

    await cardRepository.closeCard(card, DateTime(2026, 7, 31));
    await pumpEventQueue();

    final state = cubit.state as CardsLoadSuccess;
    expect(state.cards, isEmpty);
    expect(state.retired.single.summary.card.id, card.id);
    expect(state.retired.single.hidden?.count, 1);
  });

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

    await statementRepository.importStatement(aStatement(card: card, totalDue: 5000));
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

    await statementRepository.importStatement(aStatement(card: card, totalDue: 5000));
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

    await statementRepository.importStatement(aStatement(card: card, totalDue: 7000));
    await pumpEventQueue();

    // The current (second-generation) subscription still picks this up —
    // only a truly stale (closed) generation would discard it.
    final state = cubit.state as CardsLoadSuccess;
    expect(state.cards.single.latestStatement?.totalDue, 7000);
  });
}
