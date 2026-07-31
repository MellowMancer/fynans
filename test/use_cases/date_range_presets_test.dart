import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/use_cases/date_range_presets.dart';

void main() {
  // A Wednesday, so week boundaries are unambiguous.
  final now = DateTime(2026, 7, 15, 14, 30);

  group('resolveDateRangePreset', () {
    test('today covers exactly the current day', () {
      final range = resolveDateRangePreset(DateRangePreset.today, now: now);

      expect(range.isSingleDay, isTrue);
      expect(range.start, DateTime(2026, 7, 15));
      expect(range.end.hour, 23);
      expect(range.contains(now), isTrue);
      expect(range.contains(DateTime(2026, 7, 14, 23, 59)), isFalse);
      expect(range.contains(DateTime(2026, 7, 16)), isFalse);
    });

    test('this week runs Monday to Sunday around the given day', () {
      final range = resolveDateRangePreset(DateRangePreset.thisWeek, now: now);

      expect(range.start, DateTime(2026, 7, 13)); // Monday
      expect(range.start.weekday, DateTime.monday);
      expect(range.end.weekday, DateTime.sunday);
      expect(range.contains(DateTime(2026, 7, 19, 23, 0)), isTrue);
      expect(range.contains(DateTime(2026, 7, 12)), isFalse);
    });

    test('this month spans the whole calendar month', () {
      final range = resolveDateRangePreset(DateRangePreset.thisMonth, now: now);

      expect(range.start, DateTime(2026, 7, 1));
      expect(range.contains(DateTime(2026, 7, 31, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 8, 1)), isFalse);
    });

    test('this year spans Jan to Dec', () {
      final range = resolveDateRangePreset(DateRangePreset.thisYear, now: now);

      expect(range.start, DateTime(2026, 1, 1));
      expect(range.contains(DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(range.contains(DateTime(2027, 1, 1)), isFalse);
    });

    group('current FY (1 Apr – 31 Mar)', () {
      test('after April, the FY started this year', () {
        final range =
            resolveDateRangePreset(DateRangePreset.currentFy, now: now);

        expect(range.start, DateTime(2026, 4, 1));
        expect(range.contains(DateTime(2027, 3, 31, 23, 59)), isTrue);
        expect(range.contains(DateTime(2027, 4, 1)), isFalse);
        expect(range.contains(DateTime(2026, 3, 31)), isFalse);
      });

      test('before April, we are still in last year\'s FY', () {
        final range = resolveDateRangePreset(
          DateRangePreset.currentFy,
          now: DateTime(2026, 2, 10),
        );

        expect(range.start, DateTime(2025, 4, 1));
        expect(range.contains(DateTime(2026, 3, 31, 12)), isTrue);
      });
    });

    test('custom has no implicit span', () {
      expect(
        () => resolveDateRangePreset(DateRangePreset.custom, now: now),
        throwsArgumentError,
      );
    });
  });

  group('DateRange', () {
    test('spanning normalises reversed input and covers whole days', () {
      final range =
          DateRange.spanning(DateTime(2026, 7, 20), DateTime(2026, 7, 10));

      expect(range.start, DateTime(2026, 7, 10));
      expect(range.contains(DateTime(2026, 7, 20, 23, 59)), isTrue);
    });

    test('month covers the final microsecond of the last day', () {
      final range = DateRange.month(DateTime(2026, 2, 5));

      expect(range.start, DateTime(2026, 2, 1));
      expect(range.contains(DateTime(2026, 2, 28, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 3, 1)), isFalse);
    });
  });
}
