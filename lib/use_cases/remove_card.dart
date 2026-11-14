import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// How a card can leave the cards list.
enum CardRemoval {
  /// The card has no transactions and no statements, so it can be deleted.
  delete,

  /// The card has history. The user closes it or untracks it, and the
  /// history stays.
  retire,
}

/// The transactions that a card status hides: how many, and their total
/// amount.
class HiddenTransactions {
  const HiddenTransactions(this.count, this.total);

  /// Counts the [transactions] that a card with [status], closed on
  /// [closedOn], hides. The remove dialog uses it to preview a choice, and
  /// the cards page uses it to show what a retired card hides now.
  factory HiddenTransactions.of(
    List<Transaction> transactions,
    CardStatus status,
    DateTime? closedOn,
  ) {
    final hidden =
        transactions.where((t) => cardHides(status, closedOn, t.date));
    return HiddenTransactions(
      hidden.length,
      hidden.fold(0.0, (sum, t) => sum + t.amount),
    );
  }

  final int count;
  final double total;
}

/// Takes a card out of the cards list without losing money history.
///
/// A card that something refers to is never deleted: its transactions would
/// lose the fact that they were card spends.
class RemoveCard {
  RemoveCard(this._cards, this._transactions, this._statements);

  final CardRepository _cards;
  final TransactionRepository _transactions;
  final CardStatementRepository _statements;

  /// Whether [card] can be deleted, or must be closed or untracked.
  Future<CardRemoval> removalFor(PaymentCard card) async {
    final id = card.id;
    if (id == null) throw StateError('This card was never saved.');

    final transactions =
        await _transactions.listenToTransactionsForCard(id).first;
    final statement = await _statements.fetchLatestStatement(id);
    return transactions.isEmpty && statement == null
        ? CardRemoval.delete
        : CardRemoval.retire;
  }

  /// Deletes [card]. Throws a [StateError] if the card has history.
  Future<void> delete(PaymentCard card) async {
    if (await removalFor(card) != CardRemoval.delete) {
      throw StateError('A card with history must be closed or untracked.');
    }
    await _cards.deleteCard(card);
  }

  /// Closes [card] on the calendar date that contains [day].
  Future<void> close(PaymentCard card, DateTime day) =>
      _cards.closeCard(card, DateTime(day.year, day.month, day.day));

  /// Untracks [card]: all of its transactions are hidden.
  Future<void> untrack(PaymentCard card) => _cards.untrackCard(card);

  /// Makes a closed or untracked [card] active again. Every transaction that
  /// its status hid, including SMS saved while it was retired, shows again.
  Future<void> restore(PaymentCard card) => _cards.restoreCard(card);
}
