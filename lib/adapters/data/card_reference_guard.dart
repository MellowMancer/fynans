import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:fynans/ports/missing_card_exception.dart';

/// SQLite's extended result code for a failed foreign key constraint.
const _foreignKeyFailed = 787;

/// Runs [write], and turns a foreign key failure into a
/// [MissingCardException] for [cardId].
///
/// The rows that [write] touches have one foreign key, the card id, so a
/// foreign key failure always means that the card does not exist. Other
/// errors pass through unchanged.
Future<T> guardCardReference<T>(int? cardId, Future<T> Function() write) async {
  try {
    return await write();
  } on SqliteException catch (e) {
    if (cardId == null || e.extendedResultCode != _foreignKeyFailed) rethrow;
    throw MissingCardException(cardId);
  }
}
