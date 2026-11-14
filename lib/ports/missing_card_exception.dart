/// A repository throws this when a write names a card that does not exist,
/// for example because the user deleted the card during an SMS sweep.
class MissingCardException implements Exception {
  /// Creates the exception for the card id that the write named.
  const MissingCardException(this.cardId);

  /// The id of the card that does not exist.
  final int cardId;

  @override
  String toString() => 'MissingCardException: no card with id $cardId';
}
