part of 'advanced_view_bloc.dart';

@immutable
sealed class AdvancedViewEvent {}

/// Event to trigger the initial data load or a full refresh based on current filters.
final class AdvancedViewDataFetched extends AdvancedViewEvent {}

/// Event to update the selected month for filtering.
final class AdvancedViewMonthChanged extends AdvancedViewEvent {
  final DateTime newMonth;

  AdvancedViewMonthChanged(this.newMonth);
}

/// Event to set or clear the filter for a specific group.
final class AdvancedViewGroupFilterChanged extends AdvancedViewEvent {
  final String? group;

  AdvancedViewGroupFilterChanged(this.group);
}

/// Event to set or clear the filter for a specific tag.
final class AdvancedViewTagFilterChanged extends AdvancedViewEvent {
  final String? tag;

  AdvancedViewTagFilterChanged(this.tag);
}

/// Event to set or clear the filter for a specific party.
final class AdvancedViewPartyFilterChanged extends AdvancedViewEvent {
  final String? party;

  AdvancedViewPartyFilterChanged(this.party);
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
  final AdvancedViewLoadSuccess baseState;

  _AdvancedViewTransactionsUpdated(this.transactions, this.baseState);
}

/// Internal: the repository stream emitted an error.
final class _AdvancedViewStreamFailed extends AdvancedViewEvent {
  final String error;

  _AdvancedViewStreamFailed(this.error);
}