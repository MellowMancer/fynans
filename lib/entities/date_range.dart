import 'package:meta/meta.dart';

/// An inclusive span of time, used for every "which transactions?" query.
///
/// [start] is the first instant of the first day; [end] is the last microsecond
/// of the last day, so day-boundary comparisons never drop a transaction.
@immutable
class DateRange {
  const DateRange({required this.start, required this.end});

  /// The whole calendar day containing [day].
  factory DateRange.day(DateTime day) => DateRange(
        start: _startOfDay(day),
        end: _endOfDay(day),
      );

  /// The calendar month containing [month].
  factory DateRange.month(DateTime month) => DateRange(
        start: DateTime(month.year, month.month, 1),
        end: _endOfDay(DateTime(month.year, month.month + 1, 0)),
      );

  /// Whole days from [from] to [to], inclusive, in either order.
  factory DateRange.spanning(DateTime from, DateTime to) {
    final ordered = from.isAfter(to) ? [to, from] : [from, to];
    return DateRange(
      start: _startOfDay(ordered.first),
      end: _endOfDay(ordered.last),
    );
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && !moment.isAfter(end);

  /// True when the span covers exactly one calendar day.
  bool get isSingleDay =>
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999, 999);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start .. $end)';
}
