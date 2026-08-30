import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/summarise_card.dart';
import 'cards_state.dart';

/// Streams every card's summary and transactions, live: reacts to a card
/// being added/deleted and to that card's own transactions changing (an SMS
/// import, a manual entry), same as [TransactionCubit] does for the month.
///
/// Fans out one subscription per card on top of the cards subscription
/// itself, since a card's available limit has to update live and
/// [TransactionRepository.listenToTransactionsForCard] is per-card, not a
/// single combined stream.
class CardsCubit extends Cubit<CardsState> {
  final TransactionRepository _repository;
  final CardRepository _cardRepository;

  StreamSubscription<List<CreditCard>>? _cardsSubscription;
  final Map<int, StreamSubscription<List<Transaction>>> _txnSubscriptions = {};
  final Map<int, List<Transaction>> _transactionsByCard = {};
  List<CreditCard> _cards = const [];

  /// Bumped per [loadCards] call so a late event from a superseded
  /// subscription set can be discarded instead of overwriting current state.
  int _generation = 0;

  CardsCubit(this._repository, this._cardRepository) : super(CardsInitial());

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

    for (final card in cards) {
      final id = card.id;
      if (id == null || _txnSubscriptions.containsKey(id)) continue;
      _txnSubscriptions[id] =
          _repository.listenToTransactionsForCard(id).listen((transactions) {
        if (isClosed || generation != _generation) return;
        _transactionsByCard[id] = transactions;
        _emitSummaries();
      });
    }

    _emitSummaries();
  }

  void _emitSummaries() {
    emit(CardsLoadSuccess([
      for (final card in _cards)
        CardWithTransactions(
          summary:
              summariseCard(card, _transactionsByCard[card.id] ?? const []),
          transactions: _transactionsByCard[card.id] ?? const [],
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
  }

  @override
  Future<void> close() async {
    _generation++; // invalidate any in-flight events
    await _cancelAll();
    return super.close();
  }
}
