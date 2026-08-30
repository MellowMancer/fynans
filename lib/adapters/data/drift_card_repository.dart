import 'package:drift/drift.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/entities/credit_card.dart';
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
  Future<void> saveCard(CreditCard card) async {
    card.id = await _db.into(_db.cards).insert(_toRow(card));
  }

  @override
  Future<void> deleteCard(CreditCard card) async {
    final id = card.id;
    if (id == null) {
      throw StateError('Cannot delete a card that was never saved.');
    }
    await (_db.delete(_db.cards)..where((c) => c.id.equals(id))).go();
  }

  @override
  Stream<List<CreditCard>> watchCards() =>
      _db.select(_db.cards).watch().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<List<CreditCard>> fetchCards() async =>
      (await _db.select(_db.cards).get()).map(_toEntity).toList();

  CardsCompanion _toRow(CreditCard c) => CardsCompanion.insert(
        issuer: c.issuer,
        last4: c.last4,
        creditLimit: c.creditLimit,
        nickname: Value(c.nickname),
      );

  CreditCard _toEntity(CardRow row) => CreditCard()
    ..id = row.id
    ..issuer = row.issuer
    ..last4 = row.last4
    ..creditLimit = row.creditLimit
    ..nickname = row.nickname;
}
