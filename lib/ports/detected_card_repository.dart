import 'package:fynans/entities/detected_card.dart';

/// Abstract seam for "cards seen in SMS but not registered" candidates.
abstract class DetectedCardRepository {
  /// Records or updates a sighting for (issuerGuess, last4). No-ops if a
  /// dismissed sighting already exists for that pair — dismissal is sticky.
  Future<void> recordSighting({
    required String sender,
    required String issuerGuess,
    required String last4,
    required DateTime seenAt,
  });

  /// Live, non-dismissed sightings, most recently seen first.
  Stream<List<DetectedCard>> watchPending();

  /// Marks [card] as "not mine" — stays on disk so a future sighting of the
  /// same (issuerGuess, last4) doesn't recreate the prompt.
  Future<void> dismiss(DetectedCard card);

  /// Removes [card] entirely — used once it's been registered as a real
  /// card, so the sighting doesn't linger looking like an open prompt.
  Future<void> remove(DetectedCard card);
}
