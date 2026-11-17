import 'package:fynans/entities/payment_card.dart';

/// Abstract seam between the domain/presentation layer and wherever
/// [PaymentCard]s are persisted.
abstract class CardRepository {
  Future<void> saveCard(PaymentCard card);

  /// Deletes the card row. The database refuses this while any transaction
  /// or statement still refers to the card; `RemoveCard` decides when a
  /// delete is allowed.
  Future<void> deleteCard(PaymentCard card);

  /// Marks [card] as closed. [day] is the start (midnight) of the closing
  /// date. The card's transactions after that date are hidden.
  Future<void> closeCard(PaymentCard card, DateTime day);

  /// Marks [card] as untracked. All of its transactions are hidden.
  Future<void> untrackCard(PaymentCard card);

  /// Makes a closed or untracked [card] active again, with no closing date.
  Future<void> restoreCard(PaymentCard card);

  /// Live list of every card, whatever its status. The cards page shows the
  /// active cards and, in a separate section, the closed and untracked ones.
  Stream<List<PaymentCard>> watchCards();

  /// Every card, whatever its status. The SMS ingestor needs closed and
  /// untracked cards too, so that their SMS still match a known card.
  Future<List<PaymentCard>> fetchCards();
}
