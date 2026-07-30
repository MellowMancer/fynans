import 'package:flutter/material.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:intl/intl.dart';

/// Height of a day cell; also the band's diameter, so a pill radius of
/// `height / 2` produces exact semi-circles at every vertical edge.
const double _kCellHeight = 40;

const int _kDaysPerWeek = DateTime.daysPerWeek;

/// A contiguous run of selected days within one week row, as column indices.
@immutable
class SelectedRun {
  const SelectedRun({required this.startIndex, required this.endIndex});

  final int startIndex;
  final int endIndex;

  int get length => endIndex - startIndex + 1;

  @override
  bool operator ==(Object other) =>
      other is SelectedRun &&
      other.startIndex == startIndex &&
      other.endIndex == endIndex;

  @override
  int get hashCode => Object.hash(startIndex, endIndex);

  @override
  String toString() => 'SelectedRun($startIndex..$endIndex)';
}

/// Splits one week row into the contiguous stretches covered by [range].
///
/// A run breaks wherever the row does — at a leading/trailing blank (so the
/// first and last day of a month always terminate a run) and at any gap. Each
/// run is drawn as its own pill, which is what gives every vertical edge a
/// rounded cap.
List<SelectedRun> selectedRunsInWeek(List<DateTime?> week, DateRange? range) {
  if (range == null) return const [];

  final runs = <SelectedRun>[];
  int? runStart;

  for (var i = 0; i < week.length; i++) {
    final day = week[i];
    final selected = day != null && range.contains(day);

    if (selected) {
      runStart ??= i;
    } else if (runStart != null) {
      runs.add(SelectedRun(startIndex: runStart, endIndex: i - 1));
      runStart = null;
    }
  }
  if (runStart != null) {
    runs.add(SelectedRun(startIndex: runStart, endIndex: week.length - 1));
  }
  return runs;
}

/// Full-screen calendar for picking a custom span. Selected days are drawn as
/// an outlined band with semi-circular caps at every vertical edge.
class DateRangeCalendarSheet extends StatefulWidget {
  const DateRangeCalendarSheet({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateRange? initialRange;

  /// Opens the picker; resolves to the chosen span, or null if dismissed.
  static Future<DateRange?> show({
    required BuildContext context,
    required DateTime firstDate,
    required DateTime lastDate,
    DateRange? initialRange,
  }) {
    return showModalBottomSheet<DateRange>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxHeight: 640),
      builder: (_) => DateRangeCalendarSheet(
        firstDate: firstDate,
        lastDate: lastDate,
        initialRange: initialRange,
      ),
    );
  }

  @override
  State<DateRangeCalendarSheet> createState() => _DateRangeCalendarSheetState();
}

class _DateRangeCalendarSheetState extends State<DateRangeCalendarSheet> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
  }

  DateRange? get _range {
    if (_start == null) return null;
    return DateRange.spanning(_start!, _end ?? _start!);
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      final start = _start;
      // A complete span (or none) starts a new selection; otherwise extend.
      if (start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(start)) {
        _start = day;
        _end = start;
      } else {
        _end = day;
      }
    });
  }

  List<DateTime> get _months {
    final months = <DateTime>[];
    var cursor = DateTime(widget.firstDate.year, widget.firstDate.month);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month);
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final months = _months;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppSectionLabel('Custom range'),
                AppSpacing.gapXs,
                Text(
                  range == null ? 'Pick a start date' : Fmt.range(range),
                  style: AppTypography.h2,
                ),
              ],
            ),
          ),
          const _WeekdayHeader(),
          const Divider(),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: months.length,
              // Chronological with the latest month at the BOTTOM. `reverse`
              // lays index 0 at the bottom edge, which also means the sheet
              // opens on the newest month instead of five years ago.
              reverse: true,
              itemBuilder: (context, index) => _MonthGrid(
                month: months[months.length - 1 - index],
                range: range,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                onDayTapped: _onDayTapped,
              ),
            ),
          ),
          const Divider(),
          AppSheetActions(
            secondaryLabel: 'Cancel',
            onSecondary: () => Navigator.pop(context),
            primaryLabel: 'Apply',
            onPrimary:
                range == null ? null : () => Navigator.pop(context, range),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    // Monday-first, matching the week grouping and "This Week" preset.
    final labels = DateFormat().dateSymbols.STANDALONENARROWWEEKDAYS;
    final ordered = [...labels.sublist(1), labels.first];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final label in ordered)
            Expanded(
              child: Center(child: MonoText.small(label)),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.range,
    required this.firstDate,
    required this.lastDate,
    required this.onDayTapped,
  });

  final DateTime month;
  final DateRange? range;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDayTapped;

  /// The month laid out as Monday-first week rows, padded with nulls.
  List<List<DateTime?>> get _weeks {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (DateTime(month.year, month.month, 1).weekday -
            DateTime.monday +
            _kDaysPerWeek) %
        _kDaysPerWeek;

    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leading, null),
      for (var d = 1; d <= daysInMonth; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % _kDaysPerWeek != 0) {
      cells.add(null);
    }

    return [
      for (var i = 0; i < cells.length; i += _kDaysPerWeek)
        cells.sublist(i, i + _kDaysPerWeek),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSectionLabel(Fmt.monthYear(month)),
          AppSpacing.gapSm,
          for (final week in _weeks)
            _WeekRow(
              week: week,
              range: range,
              firstDate: firstDate,
              lastDate: lastDate,
              onDayTapped: onDayTapped,
            ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.range,
    required this.firstDate,
    required this.lastDate,
    required this.onDayTapped,
  });

  final List<DateTime?> week;
  final DateRange? range;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDayTapped;

  bool _selectable(DateTime day) =>
      !day.isBefore(DateTime(firstDate.year, firstDate.month, firstDate.day)) &&
      !day.isAfter(DateTime(lastDate.year, lastDate.month, lastDate.day));

  @override
  Widget build(BuildContext context) {
    final runs = selectedRunsInWeek(week, range);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _kDaysPerWeek;

        return SizedBox(
          height: _kCellHeight,
          child: Stack(
            children: [
              // The band sits behind the numbers. Every run is its own pill, so
              // both of its vertical edges are capped with a semi-circle.
              for (final run in runs)
                Positioned(
                  left: run.startIndex * cellWidth,
                  width: run.length * cellWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(_kCellHeight / 2),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final day in week)
                    Expanded(
                      child: day == null
                          ? const SizedBox.shrink()
                          : _DayCell(
                              day: day,
                              isSelected: range?.contains(day) ?? false,
                              isEndpoint: _isEndpoint(day),
                              enabled: _selectable(day),
                              onTap: () => onDayTapped(day),
                            ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isEndpoint(DateTime day) {
    final r = range;
    if (r == null) return false;
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    return sameDay(day, r.start) || sameDay(day, r.end);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isEndpoint,
    required this.enabled,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isEndpoint;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.inkFaint
        : isEndpoint
            ? AppColors.onDark
            : isSelected
                ? AppColors.accentStrong
                : AppColors.ink;

    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Center(
        child: Container(
          width: _kCellHeight - 8,
          height: _kCellHeight - 8,
          alignment: Alignment.center,
          decoration: isEndpoint
              ? const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                )
              : null,
          child: MonoText(
            '${day.day}',
            style: AppTypography.monoSmall,
            color: color,
          ),
        ),
      ),
    );
  }
}
