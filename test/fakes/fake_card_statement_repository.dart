import 'dart:async';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/ports/card_statement_repository.dart';

/// In-memory [CardStatementRepository] for use in tests.
class FakeCardStatementRepository implements CardStatementRepository {
  final List<CardStatement> _statements = [];

  int _nextId = 0;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<void> dispose() => _changes.close();

  CardStatement? _latestFor(int cardId) {
    final forCard = _statements.where((s) => s.cardId == cardId).toList()
      ..sort((a, b) => b.statementDate.compareTo(a.statementDate));
    return forCard.isEmpty ? null : forCard.first;
  }

  @override
  Future<bool> importStatement(CardStatement statement) async {
    // Mirrors the Drift schema's unique smsId index — insert-or-ignore, same
    // reasoning as FakeCardRepository mirroring the unique (issuer, last4).
    final smsId = statement.smsId;
    if (smsId != null && _statements.any((s) => s.smsId == smsId)) {
      return false;
    }
    statement.id = ++_nextId;
    _statements.add(statement);
    _notify();
    return true;
  }

  @override
  Stream<CardStatement?> watchLatestStatement(int cardId) {
    late final StreamController<CardStatement?> controller;
    StreamSubscription<void>? watcher;

    controller = StreamController<CardStatement?>(
      onListen: () {
        controller.add(_latestFor(cardId));
        watcher = _changes.stream
            .listen((_) => controller.add(_latestFor(cardId)));
      },
      onCancel: () async {
        await watcher?.cancel();
        watcher = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<CardStatement?> fetchLatestStatement(int cardId) async =>
      _latestFor(cardId);

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
