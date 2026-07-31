import 'package:fynans/entities/date_range.dart';

/// The quick spans offered by the advanced view's range selector.
enum DateRangePreset {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year'),
  currentFy('Current FY'),
  custom('Custom Range');

  const DateRangePreset(this.label);

  /// User-facing chip label.
  final String label;

  /// [custom] is resolved from dates the user picks, not from [resolve].
  bool get isCustom => this == DateRangePreset.custom;
}

/// The day a week starts on.
const int kWeekStartsOn = DateTime.monday;

/// The month the financial year starts in — April, per the Indian FY (1 Apr –
/// 31 Mar) this app's currency and bank parsing target.
const int kFinancialYearStartMonth = DateTime.april;

/// Turns a preset into a concrete span, relative to [now] (injectable so the
/// resolution is deterministic in tests).
DateRange resolveDateRangePreset(
  DateRangePreset preset, {
  required DateTime now,
}) {
  switch (preset) {
    case DateRangePreset.today:
      return DateRange.day(now);

    case DateRangePreset.thisWeek:
      final daysSinceWeekStart = (now.weekday - kWeekStartsOn + 7) % 7;
      final weekStart = now.subtract(Duration(days: daysSinceWeekStart));
      return DateRange.spanning(weekStart, weekStart.add(
        const Duration(days: 6),
      ));

    case DateRangePreset.thisMonth:
      return DateRange.month(now);

    case DateRangePreset.thisYear:
      return DateRange.spanning(
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31),
      );

    case DateRangePreset.currentFy:
      // Before April we are still in the FY that began last April.
      final startYear =
          now.month >= kFinancialYearStartMonth ? now.year : now.year - 1;
      return DateRange.spanning(
        DateTime(startYear, kFinancialYearStartMonth, 1),
        DateTime(startYear + 1, kFinancialYearStartMonth, 1)
            .subtract(const Duration(days: 1)),
      );

    case DateRangePreset.custom:
      throw ArgumentError(
        'custom has no implicit span — build a DateRange from the user\'s dates',
      );
  }
}
