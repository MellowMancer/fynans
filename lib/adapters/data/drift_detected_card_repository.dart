import 'package:drift/drift.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/ports/detected_card_repository.dart';

/// Drift-backed implementation of [DetectedCardRepository].
class DriftDetectedCardRepository implements DetectedCardRepository {
  DriftDetectedCardRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> recordSighting({
    required String sender,
    required String issuerGuess,
    required String last4,
    required DateTime seenAt,
  }) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.detectedCards)
            ..where((d) =>
                d.issuerGuess.equals(issuerGuess) & d.last4.equals(last4)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.detectedCards).insert(
              DetectedCardsCompanion.insert(
                issuerGuess: issuerGuess,
                sender: sender,
                last4: last4,
                firstSeen: seenAt,
                lastSeen: seenAt,
              ),
            );
        return;
      }

      // Dismissal is sticky — a re-sighting must not resurrect the prompt.
      if (existing.dismissed) return;

      await (_db.update(_db.detectedCards)
            ..where((d) => d.id.equals(existing.id)))
          .write(DetectedCardsCompanion(
        sender: Value(sender),
        lastSeen: Value(seenAt),
        sightingCount: Value(existing.sightingCount + 1),
      ));
    });
  }

  @override
  Stream<List<DetectedCard>> watchPending() => (_db.select(_db.detectedCards)
        ..where((d) => d.dismissed.equals(false))
        ..orderBy([(d) => OrderingTerm.desc(d.lastSeen)]))
      .watch()
      .map((rows) => rows.map(_toEntity).toList());

  @override
  Future<void> dismiss(DetectedCard card) async {
    final id = card.id;
    if (id == null) return;
    await (_db.update(_db.detectedCards)..where((d) => d.id.equals(id)))
        .write(const DetectedCardsCompanion(dismissed: Value(true)));
  }

  @override
  Future<void> remove(DetectedCard card) async {
    final id = card.id;
    if (id == null) return;
    await (_db.delete(_db.detectedCards)..where((d) => d.id.equals(id))).go();
  }

  DetectedCard _toEntity(DetectedCardRow row) => DetectedCard()
    ..id = row.id
    ..issuerGuess = row.issuerGuess
    ..sender = row.sender
    ..last4 = row.last4
    ..firstSeen = row.firstSeen
    ..lastSeen = row.lastSeen
    ..sightingCount = row.sightingCount
    ..dismissed = row.dismissed;
}
