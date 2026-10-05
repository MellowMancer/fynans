import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/drift_detected_card_repository.dart';

void main() {
  late AppDatabase db;
  late DriftDetectedCardRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftDetectedCardRepository(db);
  });

  tearDown(() => db.close());

  test('a new sighting is inserted with sightingCount 1', () async {
    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 1),
    );

    final pending = await repo.watchPending().first;
    expect(pending, hasLength(1));
    expect(pending.single.sightingCount, 1);
    expect(pending.single.firstSeen, DateTime(2026, 1, 1));
    expect(pending.single.lastSeen, DateTime(2026, 1, 1));
  });

  test('a repeat sighting for the same (issuerGuess, last4) bumps the count '
      'and lastSeen, keeping firstSeen', () async {
    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 1),
    );
    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 10),
    );

    final pending = await repo.watchPending().first;
    expect(pending, hasLength(1));
    expect(pending.single.sightingCount, 2);
    expect(pending.single.firstSeen, DateTime(2026, 1, 1));
    expect(pending.single.lastSeen, DateTime(2026, 1, 10));
  });

  test('different (issuerGuess, last4) pairs are distinct sightings',
      () async {
    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 1),
    );
    await repo.recordSighting(
      sender: 'SBICRD',
      issuerGuess: 'SBI Card',
      last4: '5678',
      seenAt: DateTime(2026, 1, 1),
    );

    expect(await repo.watchPending().first, hasLength(2));
  });

  test('dismiss removes a sighting from watchPending but keeps the row',
      () async {
    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 1),
    );
    final card = (await repo.watchPending().first).single;

    await repo.dismiss(card);

    expect(await repo.watchPending().first, isEmpty);
    expect(await db.select(db.detectedCards).get(), hasLength(1),
        reason: 'dismissed, not deleted');
  });

  test('a dismissed sighting is not resurrected by a later sighting',
      () async {
    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 1),
    );
    final card = (await repo.watchPending().first).single;
    await repo.dismiss(card);

    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 15),
    );

    expect(await repo.watchPending().first, isEmpty);
    final stored = await db.select(db.detectedCards).get();
    expect(stored, hasLength(1), reason: 'still no duplicate row');
    expect(stored.single.sightingCount, 1,
        reason: 'the post-dismiss sighting did not bump the count either');
  });

  test('remove deletes the row entirely', () async {
    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 1),
    );
    final card = (await repo.watchPending().first).single;

    await repo.remove(card);

    expect(await db.select(db.detectedCards).get(), isEmpty);
  });

  test('watchPending emits again on a new sighting', () async {
    final seen = <int>[];
    final sub = repo.watchPending().listen((cards) => seen.add(cards.length));
    await pumpEventQueue();
    expect(seen, [0]);

    await repo.recordSighting(
      sender: 'HDFCCC',
      issuerGuess: 'HDFC',
      last4: '1234',
      seenAt: DateTime(2026, 1, 1),
    );
    await pumpEventQueue();

    expect(seen.last, 1);
    await sub.cancel();
  });
}
