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
  final String? filterGroup;
  final String? filterTag;
  final String? filterParty;
  final List<HierarchyNode> hierarchicalData;
  final MonthlySummary summary;

  const AdvancedViewLoadSuccess({
    required this.selectedMonth,
    required this.groupingHierarchy,
    this.filterGroup,
    this.filterTag,
    this.filterParty,
    required this.hierarchicalData,
    required this.summary,
  });

  AdvancedViewLoadSuccess copyWith({
    DateTime? selectedMonth,
    List<GroupingOption>? groupingHierarchy,
    String? filterGroup,
    String? filterTag,
    String? filterParty,
    List<HierarchyNode>? hierarchicalData,
    MonthlySummary? summary,
    bool clearGroup = false,
    bool clearTag = false,
    bool clearParty = false,
  }) {
    return AdvancedViewLoadSuccess(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      groupingHierarchy: groupingHierarchy ?? this.groupingHierarchy,
      filterGroup: clearGroup ? null : filterGroup ?? this.filterGroup,
      filterTag: clearTag ? null : filterTag ?? this.filterTag,
      filterParty: clearParty ? null : filterParty ?? this.filterParty,
      hierarchicalData: hierarchicalData ?? this.hierarchicalData,
      summary: summary ?? this.summary,
    );
  }
}


