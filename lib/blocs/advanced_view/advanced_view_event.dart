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

/// Event to set or clear the filter for a specific recipient.
final class AdvancedViewRecipientFilterChanged extends AdvancedViewEvent {
  final String? recipient;

  AdvancedViewRecipientFilterChanged(this.recipient);
}

/// Event to update the multi-level grouping hierarchy.
/// The list defines the order of grouping (primary, secondary, etc.).
final class AdvancedViewHierarchyChanged extends AdvancedViewEvent {
  final List<GroupingOption> newHierarchy;

  AdvancedViewHierarchyChanged(this.newHierarchy);
}