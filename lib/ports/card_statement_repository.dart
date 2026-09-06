import 'package:fynans/entities/card_statement.dart';

/// Abstract seam between the domain/presentation layer and wherever
/// [CardStatement]s are persisted.
abstract class CardStatementRepository {
  /// Insert-or-ignore on [CardStatement.smsId], same reasoning as
  /// `TransactionRepository.importTransaction`: the launch sweep re-scans the
  /// whole inbox, so re-importing an already-seen statement must be a no-op,
  /// not an error. Returns whether a new row was actually inserted.
  Future<bool> importStatement(CardStatement statement);

  /// The most recent statement for [cardId], or null if none has been
  /// parsed yet. Live — reacts to a new statement SMS being imported.
  Stream<CardStatement?> watchLatestStatement(int cardId);

  Future<CardStatement?> fetchLatestStatement(int cardId);
}
