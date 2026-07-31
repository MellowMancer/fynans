import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/widgets/date_range_calendar.dart';

/// A Monday-first week row for the given days of one month.
List<DateTime?> week(int year, int month, List<int?> days) =>
    [for (final d in days) d == null ? null : DateTime(year, month, d)];

void main() {
  _calendarOrderTests();

  group('selectedRunsInWeek', () {
    test('no range means no band', () {
      expect(
        selectedRunsInWeek(week(2026, 7, [13, 14, 15, 16, 17, 18, 19]), null),
        isEmpty,
      );
    });

    test('a fully covered week is one run spanning the row', () {
      final runs = selectedRunsInWeek(
        week(2026, 7, [13, 14, 15, 16, 17, 18, 19]),
        DateRange.spanning(DateTime(2026, 7, 1), DateTime(2026, 7, 31)),
      );

      expect(runs, [const SelectedRun(startIndex: 0, endIndex: 6)]);
      expect(runs.single.length, 7);
    });

    test('a partial week yields a run with both edges inside the row', () {
      final runs = selectedRunsInWeek(
        week(2026, 7, [13, 14, 15, 16, 17, 18, 19]),
        DateRange.spanning(DateTime(2026, 7, 15), DateTime(2026, 7, 17)),
      );

      // Wed..Fri -> indices 2..4, so both vertical edges get a rounded cap.
      expect(runs, [const SelectedRun(startIndex: 2, endIndex: 4)]);
    });

    test('leading blanks break the run, capping the month start', () {
      // A month starting on Wednesday: two leading blanks.
      final runs = selectedRunsInWeek(
        week(2026, 7, [null, null, 1, 2, 3, 4, 5]),
        DateRange.spanning(DateTime(2026, 6, 20), DateTime(2026, 7, 10)),
      );

      expect(runs, [const SelectedRun(startIndex: 2, endIndex: 6)],
          reason: 'band starts at the 1st, not at the blank cells');
    });

    test('trailing blanks break the run, capping the month end', () {
      final runs = selectedRunsInWeek(
        week(2026, 7, [27, 28, 29, 30, 31, null, null]),
        DateRange.spanning(DateTime(2026, 7, 1), DateTime(2026, 8, 15)),
      );

      expect(runs, [const SelectedRun(startIndex: 0, endIndex: 4)],
          reason: 'band ends on the 31st even though the range continues');
    });

    test('a gap inside the row produces two separately capped runs', () {
      final days = week(2026, 7, [13, 14, null, 16, 17, 18, 19]);
      final runs = selectedRunsInWeek(
        days,
        DateRange.spanning(DateTime(2026, 7, 13), DateTime(2026, 7, 19)),
      );

      expect(runs, [
        const SelectedRun(startIndex: 0, endIndex: 1),
        const SelectedRun(startIndex: 3, endIndex: 6),
      ]);
    });

    test('a single selected day is a one-cell run (a full circle)', () {
      final runs = selectedRunsInWeek(
        week(2026, 7, [13, 14, 15, 16, 17, 18, 19]),
        DateRange.day(DateTime(2026, 7, 16)),
      );

      expect(runs, [const SelectedRun(startIndex: 3, endIndex: 3)]);
      expect(runs.single.length, 1);
    });
  });
}

void _calendarOrderTests() {
  testWidgets('latest month renders below earlier months', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: DateRangeCalendarSheet(
              firstDate: DateTime(2026, 5, 1),
              lastDate: DateTime(2026, 7, 30),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final july = tester.getTopLeft(find.text('JUL 2026')).dy;
    final june = tester.getTopLeft(find.text('JUN 2026')).dy;

    expect(july, greaterThan(june),
        reason: 'July (latest) should sit below June');
  });
}
