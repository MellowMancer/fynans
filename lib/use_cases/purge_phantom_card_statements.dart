import 'package:fynans/adapters/sms/sms_parser_service.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// One-time data repair for transactions imported before
/// `SmsParserService`'s statement/due-date-reminder exclusion existed: a
/// card statement SMS ("Total Due... Avl Limit: Rs.0.00... please pay
/// by...") used to be misread as a real debit for the due amount, and its
/// "Avl Limit" figure then permanently overrode the card's real spend total
/// in `summariseCard` — pinning utilization at exactly 100%. Fixing the
/// parser only stops *new* SMS from doing this; it does nothing for a row
/// already sitting in the database from before the fix, which is what this
/// purges.
///
/// Deletes the matched rows outright, not unlink — they were never real
/// spends, so they don't belong back in the main Expenses list either.
///
/// Safe to call on every launch: once the phantom rows are gone, nothing
/// matches and it's a no-op. Returns how many rows were purged.
Future<int> purgePhantomCardStatementTransactions(
  TransactionRepository repository,
) async {
  final parser = SmsParserService();

  // Wide enough to cover every real transaction date without a dedicated
  // "fetch every card transaction" repository method.
  final everything = DateRange(start: DateTime(2000), end: DateTime(2100));
  final cardTransactions = await repository.fetchTransactionsInRange(
    range: everything,
    filter: const TransactionFilter(cardScope: CardScope.onlyCards),
  );

  var purged = 0;
  for (final t in cardTransactions) {
    // Only an auto-imported row (smsId set) with its original text saved
    // can be identified this way; a manual entry has neither and is never
    // touched by this.
    final body = t.smsBody;
    if (t.smsId == null || body == null) continue;
    if (!parser.looksLikeCardStatementText(body)) continue;

    await repository.deleteTransaction(t);
    purged++;
  }
  return purged;
}
