import 'dart:async';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/ports/card_repository.dart';

/// In-memory [CardRepository] for use in tests.
class FakeCardRepository implements CardRepository {
  final List<PaymentCard> _cards = [];

  int _nextId = 0;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<void> dispose() => _changes.close();

  /// Replaces all stored cards with the given list.
  void seed(List<PaymentCard> cards) {
    _cards
      ..clear()
      ..addAll(cards.map((c) => c..id ??= ++_nextId));
    _notify();
  }

  @override
  Future<void> saveCard(PaymentCard card) async {
    // Mirrors the Drift schema's unique (issuer, type, last4) index exactly —
    // a plain SQLite index is case-sensitive, so this must be too, or the
    // fake would reject (or allow) things the real repository doesn't.
    final duplicate = _cards.any((c) =>
        c.issuer == card.issuer &&
        c.type == card.type &&
        c.last4 == card.last4);
    if (duplicate) {
      throw StateError(
          'A card for ${card.issuer} ending ${card.last4} already exists.');
    }
    card.id = ++_nextId;
    _cards.add(card);
    _notify();
  }

  @override
  Future<void> deleteCard(PaymentCard card) async {
    final id = _savedId(card);
    _cards.removeWhere((c) => c.id == id);
    _notify();
  }

  @override
  Future<void> closeCard(PaymentCard card, DateTime day) async {
    for (final c in _withId(card)) {
      c
        ..status = CardStatus.closed
        ..closedOn = day;
    }
    _notify();
  }

  @override
  Future<void> untrackCard(PaymentCard card) async {
    for (final c in _withId(card)) {
      c
        ..status = CardStatus.untracked
        ..closedOn = null;
    }
    _notify();
  }

  @override
  Stream<List<PaymentCard>> watchActiveCards() {
    late final StreamController<List<PaymentCard>> controller;
    StreamSubscription<void>? watcher;

    controller = StreamController<List<PaymentCard>>(
      onListen: () {
        controller.add(_activeCards());
        watcher =
            _changes.stream.listen((_) => controller.add(_activeCards()));
      },
      onCancel: () async {
        await watcher?.cancel();
        watcher = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<List<PaymentCard>> fetchCards() async => List.of(_cards);

  List<PaymentCard> _activeCards() =>
      _cards.where((c) => c.status == CardStatus.active).toList();

  // Like the Drift update, a missing row is not an error: the loop is empty.
  Iterable<PaymentCard> _withId(PaymentCard card) {
    final id = _savedId(card);
    return _cards.where((c) => c.id == id);
  }

  int _savedId(PaymentCard card) {
    final id = card.id;
    if (id == null) throw StateError('This card was never saved.');
    return id;
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
