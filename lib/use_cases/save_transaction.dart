import 'package:fynans/models/transaction.dart';
import 'package:fynans/repositories/transaction_repository.dart';
import 'package:fynans/utils/amount_parser.dart';

/// Separator between group names in the raw CSV group field.
const String kGroupSeparator = ',';

/// Party recorded for a credit when the user leaves the party field blank.
const String kDefaultCreditParty = 'Me';

/// Outcome of [SaveTransaction]: [isSuccess] is true when the transaction was
/// validated and persisted, otherwise [error] holds a human-readable reason.
class SaveTransactionResult {
  /// Whether the transaction was validated and persisted.
  final bool isSuccess;

  /// A human-readable failure reason, or null on success.
  final String? error;

  const SaveTransactionResult.success()
      : isSuccess = true,
        error = null;
  const SaveTransactionResult.failure(String this.error) : isSuccess = false;
}

/// Validates raw add-transaction form values, builds a [Transaction] entity,
/// and persists it via the [TransactionRepository]. Never throws on invalid
/// input — it returns a [SaveTransactionResult.failure] instead.
class SaveTransaction {
  final TransactionRepository _repository;

  SaveTransaction(this._repository);

  /// Parses [amount], splits the CSV [group] string, resolves the credit party
  /// default, constructs the [Transaction], and saves it.
  Future<SaveTransactionResult> call({
    required String amount,
    required String party,
    required String group,
    required List<String> tags,
    required bool isCredit,
    required DateTime date,
    String? note,
  }) async {
    final amountResult = parseAmount(amount);
    if (amountResult.value == null) {
      return SaveTransactionResult.failure(amountResult.error!);
    }

    final groups = group
        .split(kGroupSeparator)
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    final trimmedParty = party.trim();
    final resolvedParty = isCredit && trimmedParty.isEmpty
        ? kDefaultCreditParty
        : trimmedParty;

    final transaction = Transaction()
      ..amount = amountResult.value!
      ..date = date
      ..tags = List.of(tags)
      ..group = groups
      ..party = resolvedParty
      ..isCredit = isCredit
      ..note = (note != null && note.isNotEmpty) ? note : null;

    await _repository.saveTransaction(transaction);
    return const SaveTransactionResult.success();
  }
}
