import 'package:fynans/entities/payment_card.dart';

/// Abstract seam between the domain/presentation layer and wherever
/// [PaymentCard]s are persisted.
abstract class CardRepository {
  /// Cards are immutable after creation — there is no update, only
  /// save/delete.
  Future<void> saveCard(PaymentCard card);
  Future<void> deleteCard(PaymentCard card);

  Stream<List<PaymentCard>> watchCards();
  Future<List<PaymentCard>> fetchCards();
}
