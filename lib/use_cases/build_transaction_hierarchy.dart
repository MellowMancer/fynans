import 'package:fynans/entities/grouping_option.dart';
import 'package:fynans/entities/hierarchy_node.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'package:fynans/use_cases/date_range_presets.dart';
import 'package:intl/intl.dart';

/// Label used when a transaction has no value for the current grouping
/// dimension.
const String kUncategorizedBucket = 'Uncategorized';

/// Folds a flat transaction list into a recursive [HierarchyNode] tree by
/// applying [hierarchy] level by level.
class BuildTransactionHierarchy {
  // Hoisted: constructing a DateFormat parses its pattern and resolves locale
  // symbols, and _keysFor runs per transaction on every re-group.
  static final DateFormat _dayFormat = DateFormat('d MMM yyyy');
  static final DateFormat _monthFormat = DateFormat.yMMM();
  static final DateFormat _dayMonthFormat = DateFormat('d MMM');

  const BuildTransactionHierarchy();

  /// Groups [transactions] by each [GroupingOption] in [hierarchy] in order,
  /// summarising every node.
  List<HierarchyNode> call(
    List<Transaction> transactions,
    List<GroupingOption> hierarchy,
  ) {
    if (hierarchy.isEmpty || transactions.isEmpty) return [];

    final currentLevel = hierarchy.first;
    final remainingHierarchy = hierarchy.sublist(1);

    final Map<String, List<Transaction>> groupedMap = {};
    // Latest moment seen in each bucket, used to order time buckets.
    final Map<String, DateTime> bucketDates = {};
    for (final transaction in transactions) {
      for (final key in _keysFor(currentLevel, transaction)) {
        (groupedMap[key] ??= []).add(transaction);
        final seen = bucketDates[key];
        if (seen == null || transaction.date.isAfter(seen)) {
          bucketDates[key] = transaction.date;
        }
      }
    }

    final nodes = groupedMap.entries.map((entry) {
      final groupTransactions = entry.value;
      return HierarchyNode(
        name: entry.key,
        summary: summariseTransactions(groupTransactions),
        transactionCount: groupTransactions.length,
        children: call(groupTransactions, remainingHierarchy),
        transactions: remainingHierarchy.isEmpty ? groupTransactions : [],
      );
    }).toList();

    if (currentLevel.isChronological) {
      // Time buckets read as a timeline (newest first), matching the flat list.
      nodes.sort((a, b) => (bucketDates[b.name] ?? DateTime(0))
          .compareTo(bucketDates[a.name] ?? DateTime(0)));
    } else {
      nodes.sort((a, b) => b.summary.total.compareTo(a.summary.total));
    }
    return nodes;
  }

  /// Label for the week containing [date], e.g.
  String _weekKey(DateTime date) {
    final daysSinceWeekStart = (date.weekday - kWeekStartsOn + 7) % 7;
    final start = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysSinceWeekStart));
    final end = start.add(const Duration(days: 6));

    final sameMonth = start.month == end.month && start.year == end.year;
    final startLabel =
        sameMonth ? '${start.day}' : _dayMonthFormat.format(start);
    return '$startLabel – ${_dayFormat.format(end)}';
  }

  /// Derives the bucket key(s) a [transaction] falls into for [option],
  /// substituting [kUncategorizedBucket] for missing values.
  List<String> _keysFor(GroupingOption option, Transaction transaction) =>
      switch (option) {
        GroupingOption.group => transaction.group.isNotEmpty
            ? transaction.group
            : const [kUncategorizedBucket],
        GroupingOption.tag => transaction.tags.isNotEmpty
            ? transaction.tags
            : const [kUncategorizedBucket],
        GroupingOption.party => transaction.party.isNotEmpty
            ? [transaction.party]
            : const [kUncategorizedBucket],
        // e.g.
        GroupingOption.day => [_dayFormat.format(transaction.date)],
        GroupingOption.week => [_weekKey(transaction.date)],
        // Three-letter month, e.g.
        GroupingOption.month => [_monthFormat.format(transaction.date)],
      };
}
