import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/entities/transaction.dart';

/// A node in a hierarchical grouping of transactions used by the advanced view.
class HierarchyNode {
  final String name;
  final MonthlySummary summary;
  final int transactionCount;
  final List<HierarchyNode> children; // Only populated for non-leaf nodes
  final List<Transaction> transactions; // Only populated for leaf nodes

  HierarchyNode({
    required this.name,
    required this.summary,
    required this.transactionCount,
    this.children = const [],
    this.transactions = const [],
  });
}
