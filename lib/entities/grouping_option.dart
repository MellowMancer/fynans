/// A dimension transactions can be grouped by in the advanced view.
enum GroupingOption {
  group('Group'),
  tag('Tag'),
  party('Party'),
  day('Day'),
  week('Week'),
  month('Month');

  const GroupingOption(this.displayName);

  /// Human-readable label for the grouping dimension.
  final String displayName;

  /// True for time buckets, which must read as a timeline rather than being
  /// ranked by amount.
  bool get isChronological =>
      this == GroupingOption.day ||
      this == GroupingOption.week ||
      this == GroupingOption.month;
}
