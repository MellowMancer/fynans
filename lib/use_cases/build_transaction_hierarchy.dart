import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/hierarchy_node.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'package:intl/intl.dart';

/// Label used when a transaction has no value for the current grouping dimension.
const String kUncategorizedBucket = 'Uncategorized';

/// Folds a flat transaction list into a recursive [HierarchyNode] tree by
/// applying [hierarchy] level by level. This is the single home for all
/// grouping/bucketing policy (canonical empty-bucket label + month format);
/// no other layer decides grouping keys.
class BuildTransactionHierarchy {
  const BuildTransactionHierarchy();

  /// Groups [transactions] by each [GroupingOption] in [hierarchy] in order,
  /// summarising every node and sorting siblings by descending total.
  List<HierarchyNode> call(
    List<Transaction> transactions,
    List<GroupingOption> hierarchy,
  ) {
    if (hierarchy.isEmpty || transactions.isEmpty) return [];

    final currentLevel = hierarchy.first;
    final remainingHierarchy = hierarchy.sublist(1);

    final Map<String, List<Transaction>> groupedMap = {};
    for (final transaction in transactions) {
      for (final key in _keysFor(currentLevel, transaction)) {
        (groupedMap[key] ??= []).add(transaction);
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

    nodes.sort((a, b) => b.summary.total.compareTo(a.summary.total));
    return nodes;
  }

  /// Derives the bucket key(s) a [transaction] falls into for [option],
  /// substituting [kUncategorizedBucket] for missing values.
  List<String> _keysFor(GroupingOption option, Transaction transaction) {
    switch (option) {
      case GroupingOption.group:
        return transaction.group.isNotEmpty
            ? transaction.group
            : [kUncategorizedBucket];
      case GroupingOption.tag:
        return transaction.tags.isNotEmpty
            ? transaction.tags
            : [kUncategorizedBucket];
      case GroupingOption.party:
        return transaction.party.isNotEmpty
            ? [transaction.party]
            : [kUncategorizedBucket];
      case GroupingOption.month:
        return [DateFormat.yMMMM().format(transaction.date)];
    }
  }
}
