part of 'advanced_view_bloc.dart';

@immutable
sealed class AdvancedViewEvent {}

/// Event to trigger the initial data load or a full refresh based on current filters.
final class AdvancedViewDataFetched extends AdvancedViewEvent {}

/// Event to change the span the advanced view reports on.
final class AdvancedViewRangeChanged extends AdvancedViewEvent {
  final DateRange range;
  final DateRangePreset preset;

  AdvancedViewRangeChanged(this.range, this.preset);
}

/// Event to update the multi-level grouping hierarchy.
/// The list defines the order of grouping (primary, secondary, etc.).
final class AdvancedViewHierarchyChanged extends AdvancedViewEvent {
  final List<GroupingOption> newHierarchy;

  AdvancedViewHierarchyChanged(this.newHierarchy);
}

/// Internal: the repository stream pushed a fresh transaction snapshot.
/// Carries the view config captured when the subscription was opened so the
/// success state can be rebuilt after the interim loading state.
final class _AdvancedViewTransactionsUpdated extends AdvancedViewEvent {
  final List<Transaction> transactions;

  _AdvancedViewTransactionsUpdated(this.transactions);
}

/// Internal: the repository stream emitted an error.
final class _AdvancedViewStreamFailed extends AdvancedViewEvent {
  final String error;

  _AdvancedViewStreamFailed(this.error);
}

/// Event carrying a wholly new filter — one event covers group, tag, party,
/// direction and amount bounds instead of one event per field.
final class AdvancedViewFilterChanged extends AdvancedViewEvent {
  final TransactionFilter filter;

  AdvancedViewFilterChanged(this.filter);
}
