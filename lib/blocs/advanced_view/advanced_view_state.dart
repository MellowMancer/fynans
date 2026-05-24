part of 'advanced_view_bloc.dart';


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

@immutable
sealed class AdvancedViewState {
  const AdvancedViewState();
}

final class AdvancedViewInitial extends AdvancedViewState {
  const AdvancedViewInitial();
}

final class AdvancedViewLoading extends AdvancedViewState {
  const AdvancedViewLoading();
}

final class AdvancedViewFailure extends AdvancedViewState {
  final String error;
  const AdvancedViewFailure(this.error);
}

final class AdvancedViewLoadSuccess extends AdvancedViewState {
  final DateTime selectedMonth;
  final List<GroupingOption> groupingHierarchy;
  final TransactionFilter filter;
  final List<HierarchyNode> hierarchicalData;
  final MonthlySummary summary;

  const AdvancedViewLoadSuccess({
    required this.selectedMonth,
    required this.groupingHierarchy,
    this.filter = const TransactionFilter.empty(),
    required this.hierarchicalData,
    required this.summary,
  });

  AdvancedViewLoadSuccess copyWith({
    DateTime? selectedMonth,
    List<GroupingOption>? groupingHierarchy,
    TransactionFilter? filter,
    List<HierarchyNode>? hierarchicalData,
    MonthlySummary? summary,
  }) {
    return AdvancedViewLoadSuccess(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      groupingHierarchy: groupingHierarchy ?? this.groupingHierarchy,
      filter: filter ?? this.filter,
      hierarchicalData: hierarchicalData ?? this.hierarchicalData,
      summary: summary ?? this.summary,
    );
  }
}
