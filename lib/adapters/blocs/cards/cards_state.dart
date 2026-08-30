import 'package:equatable/equatable.dart';
import 'package:fynans/entities/card_summary.dart';
import 'package:fynans/entities/transaction.dart';

abstract class CardsState extends Equatable {
  const CardsState();

  @override
  List<Object> get props => [];
}

class CardsInitial extends CardsState {}

class CardsLoadInProgress extends CardsState {}

/// One card's derived summary plus its own transactions — the summary drives
/// [CardTile]/the list screen, the transactions drive [CardDetailScreen]'s
/// list. Not [Equatable]: nested the same way `MonthlySummary` sits inside
/// `TransactionLoadSuccess`.
class CardWithTransactions {
  const CardWithTransactions(
      {required this.summary, required this.transactions});

  final CardSummary summary;
  final List<Transaction> transactions;
}

class CardsLoadSuccess extends CardsState {
  const CardsLoadSuccess(this.cards);

  final List<CardWithTransactions> cards;

  @override
  List<Object> get props => [cards];
}

class CardsLoadFailure extends CardsState {
  const CardsLoadFailure(this.error);

  final String error;

  @override
  List<Object> get props => [error];
}
