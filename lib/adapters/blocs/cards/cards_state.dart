import 'package:equatable/equatable.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/card_summary.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/remove_card.dart';

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
  const CardWithTransactions({
    required this.summary,
    required this.transactions,
    this.latestStatement,
    this.hidden,
  });

  final CardSummary summary;
  final List<Transaction> transactions;

  /// The most recent parsed statement for this card, or null if none has
  /// been seen yet. Drives `PaymentDueBanner` on the card detail screen.
  final CardStatement? latestStatement;

  /// What this card's status hides from the user's lists and totals. Null
  /// for an active card, which hides nothing.
  final HiddenTransactions? hidden;
}

class CardsLoadSuccess extends CardsState {
  const CardsLoadSuccess(this.cards, {this.retired = const []});

  /// The active cards.
  final List<CardWithTransactions> cards;

  /// The closed and untracked cards, for their own section of the page.
  final List<CardWithTransactions> retired;

  @override
  List<Object> get props => [cards, retired];
}

class CardsLoadFailure extends CardsState {
  const CardsLoadFailure(this.error);

  final String error;

  @override
  List<Object> get props => [error];
}
