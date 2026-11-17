import 'dart:async';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/ports/detected_card_repository.dart';

/// In-memory [DetectedCardRepository] for use in tests.
class FakeDetectedCardRepository implements DetectedCardRepository {
  final List<DetectedCard> _cards = [];

  int _nextId = 0;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<void> dispose() => _changes.close();

  void seed(List<DetectedCard> cards) {
    _cards
      ..clear()
      ..addAll(cards.map((c) => c..id ??= ++_nextId));
    _notify();
  }

  List<DetectedCard> get all => List.unmodifiable(_cards);

  @override
  Future<void> recordSighting({
    required String sender,
    required String issuerGuess,
    required String last4,
    required DateTime seenAt,
  }) async {
    DetectedCard? existing;
    for (final c in _cards) {
      if (c.issuerGuess == issuerGuess && c.last4 == last4) {
        existing = c;
        break;
      }
    }

    if (existing == null) {
      _cards.add(DetectedCard()
        ..id = ++_nextId
        ..issuerGuess = issuerGuess
        ..sender = sender
        ..last4 = last4
        ..firstSeen = seenAt
        ..lastSeen = seenAt
        ..sightingCount = 1
        ..dismissed = false);
      _notify();
      return;
    }

    if (existing.dismissed) return;

    existing
      ..sender = sender
      ..lastSeen = seenAt
      ..sightingCount += 1;
    _notify();
  }

  @override
  Stream<List<DetectedCard>> watchPending() {
    late final StreamController<List<DetectedCard>> controller;
    StreamSubscription<void>? watcher;

    List<DetectedCard> pending() => (_cards.where((c) => !c.dismissed).toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen)));

    controller = StreamController<List<DetectedCard>>(
      onListen: () {
        controller.add(pending());
        watcher = _changes.stream.listen((_) => controller.add(pending()));
      },
      onCancel: () async {
        await watcher?.cancel();
        watcher = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<void> dismiss(DetectedCard card) async {
    final id = card.id;
    for (final c in _cards) {
      if (c.id == id) c.dismissed = true;
    }
    _notify();
  }

  @override
  Future<void> remove(DetectedCard card) async {
    _cards.removeWhere((c) => c.id == card.id);
    _notify();
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
