/// A card sighted in SMS that doesn't match any registered [CreditCard] —
/// a "we noticed this, is it yours?" candidate, never a saved spend.
class DetectedCard {
  /// Storage-assigned row identity, null until the record has been saved.
  int? id;

  /// Best-effort friendly name derived from the sender; the user can retype
  /// it when confirming, so this is a starting point, not a fact.
  late String issuerGuess;

  /// The raw SMS sender that produced this sighting.
  late String sender;

  late String last4;

  late DateTime firstSeen;
  late DateTime lastSeen;

  /// How many SMS have matched this (issuerGuess, last4) pair so far.
  int sightingCount = 1;

  /// True once the user says "not mine" — the sighting stays around (so a
  /// re-sighting doesn't recreate it) but is filtered out of the prompt.
  bool dismissed = false;
}
