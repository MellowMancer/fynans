/// A dimension transactions can be grouped by in the advanced view.
/// Pure enum: the key-derivation policy lives in [BuildTransactionHierarchy].
enum GroupingOption {
  group('Group'),
  tag('Tag'),
  party('Party'),
  month('Month');

  const GroupingOption(this.displayName);

  /// Human-readable label for the grouping dimension.
  final String displayName;
}
