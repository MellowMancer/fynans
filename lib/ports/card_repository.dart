import 'package:fynans/entities/credit_card.dart';

/// Abstract seam between the domain/presentation layer and wherever
/// [CreditCard]s are persisted.
abstract class CardRepository {
  /// Cards are immutable after creation — there is no update, only
  /// save/delete.
  Future<void> saveCard(CreditCard card);
  Future<void> deleteCard(CreditCard card);

  Stream<List<CreditCard>> watchCards();
  Future<List<CreditCard>> fetchCards();
}
