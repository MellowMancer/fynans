import 'package:drift/drift.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/ports/card_repository.dart';

/// Drift-backed implementation of [CardRepository].
///
/// Takes its database rather than reaching for a global, same reasoning as
/// [DriftTransactionRepository]: a second connection over the same file would
/// not share Drift's update notifications.
class DriftCardRepository implements CardRepository {
  DriftCardRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> saveCard(PaymentCard card) async {
    card.id = await _db.into(_db.cards).insert(_toRow(card));
  }

  @override
  Future<void> deleteCard(PaymentCard card) async {
    final id = _savedId(card);
    await (_db.delete(_db.cards)..where((c) => c.id.equals(id))).go();
  }

  @override
  Future<void> closeCard(PaymentCard card, DateTime day) => _setStatus(
        card,
        CardsCompanion(
          status: const Value(CardStatus.closed),
          closedOn: Value(day),
        ),
      );

  @override
  Future<void> untrackCard(PaymentCard card) => _setStatus(
        card,
        const CardsCompanion(
          status: Value(CardStatus.untracked),
          closedOn: Value(null),
        ),
      );

  @override
  Stream<List<PaymentCard>> watchActiveCards() => (_db.select(_db.cards)
        ..where((c) => c.status.equalsValue(CardStatus.active)))
      .watch()
      .map((rows) => rows.map(_toEntity).toList());

  Future<void> _setStatus(PaymentCard card, CardsCompanion change) async {
    final id = _savedId(card);
    await (_db.update(_db.cards)..where((c) => c.id.equals(id))).write(change);
  }

  int _savedId(PaymentCard card) {
    final id = card.id;
    if (id == null) throw StateError('This card was never saved.');
    return id;
  }

  @override
  Future<List<PaymentCard>> fetchCards() async =>
      (await _db.select(_db.cards).get()).map(_toEntity).toList();

  CardsCompanion _toRow(PaymentCard c) => CardsCompanion.insert(
        issuer: c.issuer,
        last4: c.last4,
        accountLast4: Value(c.accountLast4),
        type: c.type,
        status: c.status,
        closedOn: Value(c.closedOn),
        creditLimit: Value(c.creditLimit),
        nickname: Value(c.nickname),
      );

  PaymentCard _toEntity(CardRow row) => PaymentCard()
    ..id = row.id
    ..issuer = row.issuer
    ..last4 = row.last4
    ..accountLast4 = row.accountLast4
    ..type = row.type
    ..status = row.status
    ..closedOn = row.closedOn
    ..creditLimit = row.creditLimit
    ..nickname = row.nickname;
}
