import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/amount_parser.dart';

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
/// and persists it via the [TransactionRepository].
class SaveTransaction {
  final TransactionRepository _repository;

  SaveTransaction(this._repository);

  /// Parses [amount], splits the CSV [group] string, resolves the credit party
  /// default, constructs the [Transaction], and saves it.
  ///
  /// [existing], when set, is the saved row that the user edits. The new
  /// values replace it, and it keeps its id and its SMS. An SMS row also
  /// keeps the amount and the date from its SMS, whatever [amount] and [date]
  /// say.
  Future<SaveTransactionResult> call({
    required String amount,
    required String party,
    required String group,
    required List<String> tags,
    required bool isInflow,
    required DateTime date,
    String? note,
    Transaction? existing,
    int? cardId,
  }) async {
    final fromSms = existing != null && existing.isAutoImported;
    final amountResult = parseAmount(amount);
    final parsedAmount = fromSms ? existing.amount : amountResult.value;
    if (parsedAmount == null) {
      return SaveTransactionResult.failure(amountResult.error!);
    }

    final groups = group
        .split(kGroupSeparator)
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    final trimmedParty = party.trim();
    final resolvedParty =
        isInflow && trimmedParty.isEmpty ? kDefaultCreditParty : trimmedParty;

    final transaction = Transaction()
      ..id = existing?.id
      ..amount = parsedAmount
      ..date = fromSms ? existing.date : date
      ..tags = List.of(tags)
      ..group = groups
      ..party = resolvedParty
      ..isInflow = isInflow
      ..note = (note != null && note.isNotEmpty) ? note : null
      ..smsId = existing?.smsId
      ..smsBody = existing?.smsBody
      // An edit keeps the row's own card and the limit that its SMS reported.
      ..cardId = existing == null ? cardId : existing.cardId
      ..cardAvailableLimit = existing?.cardAvailableLimit;

    if (existing == null) {
      await _repository.saveTransaction(transaction);
    } else {
      await _repository.updateTransaction(transaction);
    }
    return const SaveTransactionResult.success();
  }
}
