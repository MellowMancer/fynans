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
  /// day. The card's transactions after that day are hidden.
  Future<void> closeCard(PaymentCard card, DateTime day);

  /// Marks [card] as untracked. All of its transactions are hidden.
  Future<void> untrackCard(PaymentCard card);

  /// Live list of the active cards: the cards that the cards list shows.
  Stream<List<PaymentCard>> watchActiveCards();

  /// Every card, whatever its status. The SMS ingestor needs closed and
  /// untracked cards too, so that their SMS still match a known card.
  Future<List<PaymentCard>> fetchCards();
}
