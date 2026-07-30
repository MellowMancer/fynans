part of 'advanced_view_bloc.dart';

@immutable
sealed class AdvancedViewState {
  const AdvancedViewState();
}

final class AdvancedViewLoading extends AdvancedViewState {
  const AdvancedViewLoading();
}

final class AdvancedViewFailure extends AdvancedViewState {
  final String error;
  const AdvancedViewFailure(this.error);
}

final class AdvancedViewLoadSuccess extends AdvancedViewState {
  final DateRange range;

  /// Which quick-span chip produced [range]; [DateRangePreset.custom] when the
  /// user picked their own dates.
  final DateRangePreset preset;
  final List<GroupingOption> groupingHierarchy;
  final TransactionFilter filter;
  final List<HierarchyNode> hierarchicalData;
  final MonthlySummary summary;

  const AdvancedViewLoadSuccess({
    required this.range,
    required this.preset,
    required this.groupingHierarchy,
    this.filter = const TransactionFilter.empty(),
    required this.hierarchicalData,
    required this.summary,
  });

  AdvancedViewLoadSuccess copyWith({
    DateRange? range,
    DateRangePreset? preset,
    List<GroupingOption>? groupingHierarchy,
    TransactionFilter? filter,
    List<HierarchyNode>? hierarchicalData,
    MonthlySummary? summary,
  }) {
    return AdvancedViewLoadSuccess(
      range: range ?? this.range,
      preset: preset ?? this.preset,
      groupingHierarchy: groupingHierarchy ?? this.groupingHierarchy,
      filter: filter ?? this.filter,
      hierarchicalData: hierarchicalData ?? this.hierarchicalData,
      summary: summary ?? this.summary,
    );
  }
}
