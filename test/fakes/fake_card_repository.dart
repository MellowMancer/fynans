import 'dart:async';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/ports/card_repository.dart';

/// In-memory [CardRepository] for use in tests.
class FakeCardRepository implements CardRepository {
  final List<CreditCard> _cards = [];

  int _nextId = 0;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<void> dispose() => _changes.close();

  /// Replaces all stored cards with the given list.
  void seed(List<CreditCard> cards) {
    _cards
      ..clear()
      ..addAll(cards.map((c) => c..id ??= ++_nextId));
    _notify();
  }

  @override
  Future<void> saveCard(CreditCard card) async {
    // Mirrors the Drift schema's unique (issuer, last4) index exactly — a
    // plain SQLite index is case-sensitive, so this must be too, or the fake
    // would reject (or allow) things the real repository doesn't.
    final duplicate =
        _cards.any((c) => c.issuer == card.issuer && c.last4 == card.last4);
    if (duplicate) {
      throw StateError(
          'A card for ${card.issuer} ending ${card.last4} already exists.');
    }
    card.id = ++_nextId;
    _cards.add(card);
    _notify();
  }

  @override
  Future<void> deleteCard(CreditCard card) async {
    final id = card.id;
    if (id == null) {
      throw StateError('Cannot delete a card that was never saved.');
    }
    _cards.removeWhere((c) => c.id == id);
    _notify();
  }

  @override
  Stream<List<CreditCard>> watchCards() {
    late final StreamController<List<CreditCard>> controller;
    StreamSubscription<void>? watcher;

    controller = StreamController<List<CreditCard>>(
      onListen: () {
        controller.add(List.of(_cards));
        watcher =
            _changes.stream.listen((_) => controller.add(List.of(_cards)));
      },
      onCancel: () async {
        await watcher?.cancel();
        watcher = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<List<CreditCard>> fetchCards() async => List.of(_cards);

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
