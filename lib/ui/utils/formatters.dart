import 'package:fynans/entities/date_range.dart';
import 'package:intl/intl.dart';

/// The single home for user-facing value formatting. Previously `capitalize`
/// was reimplemented in seven places (and threw on empty strings) and the `₹`
/// prefix was hand-built in a dozen — everything routes through here now.
abstract final class Fmt {
  static const String currencySymbol = '₹';

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: currencySymbol,
    decimalDigits: 2,
  );

  static final NumberFormat _moneyWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: currencySymbol,
    decimalDigits: 0,
  );

  /// Money, e.g. `₹1,23,456.78`. Pass [decimals] `0` for compact columns and
  /// [signed] to prefix an explicit `+`/`-`.
  static String money(
    double amount, {
    int decimals = 2,
    bool signed = false,
  }) {
    final formatted = (decimals == 0 ? _moneyWhole : _money)
        .format(amount.abs());
    if (!signed) return amount < 0 ? '-$formatted' : formatted;
    return amount < 0 ? '-$formatted' : '+$formatted';
  }

  /// What the counterparty is called, by direction: money coming in was paid by
  /// a **Sender**; money going out was paid to a **Recipient**.
  static String partyLabel({required bool isCredit}) =>
      isCredit ? 'Sender' : 'Recipient';

  /// Upper-cases the first character. Empty-safe (the old inline versions
  /// crashed on `''`).
  static String capitalize(String value) {
    if (value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Capitalizes each comma-separated entry, e.g. `food, travel` →
  /// `Food, Travel`.
  static String capitalizeAll(Iterable<String> values) =>
      values.map(capitalize).join(', ');

  /// `Jul 2026` — the canonical month label. Months are always the three-letter
  /// abbreviation, never the full name.
  static final DateFormat _monthYear = DateFormat.yMMM();
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _fullDate = DateFormat('d MMM yyyy');
  static final DateFormat _dayMonthTime = DateFormat('d MMM, h:mm a');
  static final DateFormat _fullDateTime = DateFormat('d MMM yyyy, h:mm a');

  static String monthYear(DateTime date) => _monthYear.format(date);

  /// `12 Jul` — date only, for aggregates where a clock time is meaningless.
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// `12 Jul 2026` — date only, for the date picker field.
  static String fullDate(DateTime date) => _fullDate.format(date);

  /// Human description of a span, collapsing shared parts:
  /// `15 Jul 2026` · `1 – 31 Jul 2026` · `1 Apr 2026 – 31 Mar 2027`.
  static String range(DateRange range) {
    if (range.isSingleDay) return fullDate(range.start);

    final sameYear = range.start.year == range.end.year;
    if (sameYear && range.start.month == range.end.month) {
      return '${range.start.day} – ${fullDate(range.end)}';
    }
    if (sameYear) {
      return '${_dayMonth.format(range.start)} – '
          '${fullDate(range.end)}';
    }
    return '${fullDate(range.start)} – ${fullDate(range.end)}';
  }

  /// `12 Jul, 2:32 pm` — compact stamp for list rows.
  static String dayMonthTime(DateTime date) => _dayMonthTime.format(date);

  /// `12 Jul 2026, 2:32 pm` — full stamp for detail views.
  static String fullDateTime(DateTime date) => _fullDateTime.format(date);
}
