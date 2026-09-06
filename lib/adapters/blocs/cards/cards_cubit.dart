import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/summarise_card.dart';
import 'cards_state.dart';

/// Streams every card's summary, transactions, and latest statement, live:
/// reacts to a card being added/deleted, to that card's own transactions
/// changing (an SMS import, a manual entry), and to a new statement SMS
/// arriving — same as [TransactionCubit] does for the month.
///
/// Fans out two subscriptions per card on top of the cards subscription
/// itself: [TransactionRepository.listenToTransactionsForCard] and
/// [CardStatementRepository.watchLatestStatement] are both per-card, not a
/// single combined stream.
class CardsCubit extends Cubit<CardsState> {
  final TransactionRepository _repository;
  final CardRepository _cardRepository;
  final CardStatementRepository _statementRepository;

  StreamSubscription<List<CreditCard>>? _cardsSubscription;
  final Map<int, StreamSubscription<List<Transaction>>> _txnSubscriptions = {};
  final Map<int, List<Transaction>> _transactionsByCard = {};
  final Map<int, StreamSubscription<CardStatement?>> _statementSubscriptions =
      {};
  final Map<int, CardStatement?> _statementByCard = {};
  List<CreditCard> _cards = const [];

  /// Bumped per [loadCards] call so a late event from a superseded
  /// subscription set can be discarded instead of overwriting current state.
  int _generation = 0;

  CardsCubit(this._repository, this._cardRepository, this._statementRepository)
      : super(CardsInitial());

  Future<void> loadCards() async {
    final generation = ++_generation;
    await _cancelAll();
    emit(CardsLoadInProgress());

    _cardsSubscription = _cardRepository.watchCards().listen(
      (cards) {
        if (isClosed || generation != _generation) return;
        _onCardsChanged(cards, generation);
      },
      onError: (Object error) {
        if (isClosed || generation != _generation) return;
        emit(CardsLoadFailure(error.toString()));
      },
    );
  }

  void _onCardsChanged(List<CreditCard> cards, int generation) {
    _cards = cards;
    final currentIds = cards.map((c) => c.id).whereType<int>().toSet();

    for (final id in _txnSubscriptions.keys.toList()) {
      if (!currentIds.contains(id)) {
        _txnSubscriptions.remove(id)?.cancel();
        _transactionsByCard.remove(id);
      }
    }
    for (final id in _statementSubscriptions.keys.toList()) {
      if (!currentIds.contains(id)) {
        _statementSubscriptions.remove(id)?.cancel();
        _statementByCard.remove(id);
      }
    }

    for (final card in cards) {
      final id = card.id;
      if (id == null) continue;
      if (!_txnSubscriptions.containsKey(id)) {
        _txnSubscriptions[id] =
            _repository.listenToTransactionsForCard(id).listen((transactions) {
          if (isClosed || generation != _generation) return;
          _transactionsByCard[id] = transactions;
          _emitSummaries();
        });
      }
      if (!_statementSubscriptions.containsKey(id)) {
        _statementSubscriptions[id] =
            _statementRepository.watchLatestStatement(id).listen((statement) {
          if (isClosed || generation != _generation) return;
          _statementByCard[id] = statement;
          _emitSummaries();
        });
      }
    }

    _emitSummaries();
  }

  void _emitSummaries() {
    emit(CardsLoadSuccess([
      for (final card in _cards)
        CardWithTransactions(
          summary: summariseCard(
            card,
            _transactionsByCard[card.id] ?? const [],
            latestStatement: _statementByCard[card.id],
          ),
          transactions: _transactionsByCard[card.id] ?? const [],
          latestStatement: _statementByCard[card.id],
        ),
    ]));
  }

  Future<void> _cancelAll() async {
    await _cardsSubscription?.cancel();
    _cardsSubscription = null;
    for (final sub in _txnSubscriptions.values) {
      await sub.cancel();
    }
    _txnSubscriptions.clear();
    _transactionsByCard.clear();
    for (final sub in _statementSubscriptions.values) {
      await sub.cancel();
    }
    _statementSubscriptions.clear();
    _statementByCard.clear();
  }

  @override
  Future<void> close() async {
    _generation++; // invalidate any in-flight events
    await _cancelAll();
    return super.close();
  }
}
