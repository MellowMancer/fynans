part of 'advanced_view_bloc.dart';


class HierarchyNode {
  final String name;
  final double totalAmount;
  final int expenseCount;
  final List<HierarchyNode> children; // Only populated for non-leaf nodes
  final List<Expense> expenses; // Only populated for leaf nodes

  HierarchyNode({
    required this.name,
    required this.totalAmount,
    required this.expenseCount,
    this.children = const [],
    this.expenses = const [],
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

/// The main state representing a successful data load and grouping.
/// It holds all the filter parameters and the resulting hierarchical data.
final class AdvancedViewLoadSuccess extends AdvancedViewState {
  final DateTime selectedMonth;
  final List<GroupingOption> groupingHierarchy;
  final String? filterGroup;
  final String? filterTag;
  final String? filterRecipient;
  final List<HierarchyNode> hierarchicalData;
  final double totalAmount;

  const AdvancedViewLoadSuccess({
    required this.selectedMonth,
    required this.groupingHierarchy,
    this.filterGroup,
    this.filterTag,
    this.filterRecipient,
    required this.hierarchicalData,
    required this.totalAmount,
  });

  /// Creates a copy of the state with updated values. This is useful in the BLoC
  /// for creating a new state based on the previous one.
  AdvancedViewLoadSuccess copyWith({
    DateTime? selectedMonth,
    List<GroupingOption>? groupingHierarchy,
    String? filterGroup,
    String? filterTag,
    String? filterRecipient,
    List<HierarchyNode>? hierarchicalData,
    double? totalAmount,
    bool clearGroup = false,
    bool clearTag = false,
    bool clearRecipient = false,
  }) {
    return AdvancedViewLoadSuccess(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      groupingHierarchy: groupingHierarchy ?? this.groupingHierarchy,
      filterGroup: clearGroup ? null : filterGroup ?? this.filterGroup,
      filterTag: clearTag ? null : filterTag ?? this.filterTag,
      filterRecipient: clearRecipient ? null : filterRecipient ?? this.filterRecipient,
      hierarchicalData: hierarchicalData ?? this.hierarchicalData,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
