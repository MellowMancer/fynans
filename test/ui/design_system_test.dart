import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/ui/widgets/date_range_selector.dart';
import 'package:fynans/use_cases/date_range_presets.dart';
import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ui/screens/test_sms_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/transaction_list_item.dart';
import 'package:fynans/ui/widgets/transaction_list_widgets.dart';

Widget _host(Widget child, {double? height}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SizedBox(height: height, width: 400, child: child),
    ),
  );
}

void main() {
  _dateRangeSelectorTests();

  group('Fmt', () {
    test('capitalize is empty-safe', () {
      expect(Fmt.capitalize(''), '');
      expect(Fmt.capitalize('food'), 'Food');
      expect(Fmt.capitalizeAll(['food', 'travel']), 'Food, Travel');
    });

    test('months are always the three-letter abbreviation', () {
      final july = DateTime(2026, 7, 15);
      expect(Fmt.monthYear(july), 'Jul 2026');
      expect(Fmt.monthYear(july), isNot(contains('July')));
      expect(Fmt.dayMonth(july), '15 Jul');
      expect(Fmt.fullDate(july), '15 Jul 2026');
    });

    test('party is labelled by direction', () {
      expect(Fmt.partyLabel(isCredit: true), 'Sender');
      expect(Fmt.partyLabel(isCredit: false), 'Recipient');
    });

    test('money renders the currency symbol and sign', () {
      expect(Fmt.money(1234.5), contains('₹'));
      expect(Fmt.money(-10), startsWith('-'));
      expect(Fmt.money(10, signed: true), startsWith('+'));
      expect(Fmt.money(1234.5, decimals: 0), isNot(contains('.')));
    });
  });

  group('mono is always upper-case', () {
    testWidgets('MonoText upper-cases its text', (tester) async {
      await tester.pumpWidget(
        _host(const Center(child: MonoText('Software and Applications'))),
      );

      expect(find.text('SOFTWARE AND APPLICATIONS'), findsOneWidget);
      expect(find.text('Software and Applications'), findsNothing);
    });

    testWidgets('mono AppKeyValue is upper-cased, the title is not',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const AppCard(
            title: 'Corner Cafe',
            child: AppKeyValue(
              label: 'Official title',
              value: 'Addendum one',
              mono: true,
            ),
          ),
        ),
      );

      // The title keeps its natural casing…
      expect(find.text('Corner Cafe'), findsOneWidget);
      // …while every mono string is upper-cased.
      expect(find.text('ADDENDUM ONE'), findsOneWidget);
    });

    testWidgets('non-mono AppKeyValue keeps natural casing', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppKeyValue(label: 'Party', value: 'Corner Cafe'),
        ),
      );

      expect(find.text('Corner Cafe'), findsOneWidget);
    });
  });

  group('design system renders', () {
    testWidgets('AppCard shows label, title and child', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppCard(
            label: 'Statement period',
            title: 'Jul 2026',
            child: Text('body'),
          ),
        ),
      );

      expect(find.text('STATEMENT PERIOD'), findsOneWidget);
      expect(find.text('Jul 2026'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppPill supports icon, tap and remove', (tester) async {
      var tapped = false;
      var removed = false;

      await tester.pumpWidget(
        _host(
          Center(
            child: AppPill(
              'Tag: food',
              icon: Icons.label,
              tone: AppPillTone.accent,
              onTap: () => tapped = true,
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tag: food'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(removed, isTrue);
    });

    testWidgets('AppButton variants build and fire', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final variant in AppButtonVariant.values)
                AppButton(
                  label: variant.name,
                  icon: Icons.check,
                  variant: variant,
                  onPressed: () => pressed++,
                ),
            ],
          ),
        ),
      );

      for (final variant in AppButtonVariant.values) {
        await tester.tap(find.text(variant.name));
      }
      expect(pressed, AppButtonVariant.values.length);
    });

    testWidgets('disabled AppButton does not fire', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _host(
          Center(
            child: AppButton(
              label: 'Save',
              loading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      expect(pressed, isFalse);
    });

    testWidgets('AppKeyValueGrid lays out without overflow', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppKeyValueGrid(
            children: [
              AppKeyValue(label: 'Party', value: 'Corner Cafe'),
              AppKeyValue(label: 'Reference', value: '541511', mono: true),
              AppKeyValue(label: 'Group', value: 'Goa trip'),
            ],
          ),
        ),
      );

      expect(find.text('PARTY'), findsOneWidget);
      expect(find.text('541511'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppMetricTile and MoneyText render amounts', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              AppMetricTile(
                label: 'Inflow',
                amount: 5000,
                tone: MoneyTone.positive,
              ),
              MoneyText(-250, tone: MoneyTone.negative),
            ],
          ),
        ),
      );

      expect(find.text('INFLOW'), findsOneWidget);
      expect(find.textContaining('5,000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppEmptyState renders title, message and action',
        (tester) async {
      await tester.pumpWidget(
        _host(
          AppEmptyState(
            icon: Icons.inbox,
            title: 'Nothing here',
            message: 'Add something',
            action: AppButton(label: 'Add', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('ParsedSmsCard', () {
    // Not const: DateTime has no const constructor.
    final sample = ParsedSms(
      sender: 'HDFCBK',
      body: 'Rs.250.00 debited from a/c XX1234 at Corner Cafe on 15-07-26.',
      details: ParsedTransactionDetails(
        type: TransactionType.debit,
        amount: 250,
        date: DateTime(2026, 7, 15),
        accountNumber: '1234',
        merchant: 'Corner Cafe',
      ),
    );

    testWidgets('hides the original SMS by default', (tester) async {
      await tester.pumpWidget(_host(ParsedSmsCard(data: sample)));

      expect(find.text('Corner Cafe'), findsOneWidget);
      expect(find.text('ORIGINAL MESSAGE'), findsNothing);
      expect(find.textContaining('debited from a/c'), findsNothing);
    });

    testWidgets('shows the verbatim SMS when asked', (tester) async {
      await tester.pumpWidget(
        _host(ParsedSmsCard(data: sample, showOriginal: true)),
      );

      expect(find.text('ORIGINAL MESSAGE'), findsOneWidget);
      // Quoted exactly — not upper-cased, unlike other mono text.
      expect(find.text(sample.body), findsOneWidget);
    });
  });

  group('TransactionListItem original SMS', () {
    Transaction txn({String? smsId, String? smsBody}) => Transaction()
      ..amount = 250
      ..date = DateTime(2026, 7, 15)
      ..tags = ['food']
      ..group = <String>[]
      ..party = 'Corner Cafe'
      ..isCredit = false
      ..note = null
      ..smsId = smsId
      ..smsBody = smsBody;

    const body = 'Rs.250.00 debited from a/c XX1234 at Corner Cafe.';

    testWidgets('shows the SMS for an auto-imported transaction',
        (tester) async {
      await tester.pumpWidget(
        _host(TransactionListItem(transaction: txn(smsId: 'abc123', smsBody: body))),
      );

      await tester.tap(find.text('Corner Cafe').first);
      await tester.pumpAndSettle();

      expect(find.text('ORIGINAL SMS'), findsOneWidget);
      expect(find.text(body), findsOneWidget);
      expect(find.text('From SMS'), findsOneWidget);
    });

    testWidgets('manual transaction shows no SMS block', (tester) async {
      await tester.pumpWidget(_host(TransactionListItem(transaction: txn())));

      await tester.tap(find.text('Corner Cafe').first);
      await tester.pumpAndSettle();

      expect(find.text('ORIGINAL SMS'), findsNothing);
      expect(find.text('Added manually'), findsOneWidget);
      // An outflow's counterparty is the recipient.
      expect(find.text('RECIPIENT'), findsOneWidget);
      expect(find.text('SENDER'), findsNothing);
    });

    testWidgets('inflow labels the counterparty as sender', (tester) async {
      final credit = txn()..isCredit = true;
      await tester.pumpWidget(_host(TransactionListItem(transaction: credit)));

      await tester.tap(find.text('Corner Cafe').first);
      await tester.pumpAndSettle();

      expect(find.text('SENDER'), findsOneWidget);
      expect(find.text('RECIPIENT'), findsNothing);
    });

    testWidgets('auto-imported record with no stored body is skipped',
        (tester) async {
      await tester.pumpWidget(
        _host(TransactionListItem(transaction: txn(smsId: 'legacy'))),
      );

      await tester.tap(find.text('Corner Cafe').first);
      await tester.pumpAndSettle();

      expect(find.text('ORIGINAL SMS'), findsNothing);
      expect(find.text('From SMS'), findsOneWidget);
    });
  });

  group('SummaryCard', () {
    testWidgets('renders month, top spending and the tap-revealed flows',
        (tester) async {
      const summary = MonthlySummary(
        total: -1500,
        totalIncome: 5000,
        totalExpenses: 6500,
        topTags: {'food': 4000, 'travel': 2500},
        topGroups: {'goa trip': 2500},
      );

      await tester.pumpWidget(
        _host(
          Column(
            children: [
              StatementPeriodRow(
                month: DateTime(2026, 7),
                onSelectMonth: () {},
              ),
              const SummaryBody(summary: summary),
            ],
          ),
          height: 700,
        ),
      );

      expect(find.text('Jul 2026'), findsOneWidget);
      expect(find.text('TOP TAGS'), findsOneWidget);

      // The split is behind a tap on the net figure now.
      expect(find.text('INFLOW'), findsNothing);
      await tester.tap(find.text('NET FOR THIS PERIOD'));
      await tester.pumpAndSettle();
      expect(find.text('INFLOW'), findsOneWidget);
      expect(find.text('OUTFLOW'), findsOneWidget);
      // A RenderFlex overflow would surface here.
      expect(tester.takeException(), isNull);
    });
  });
}

void _dateRangeSelectorTests() {
  group('DateRangeSelector', () {
    final now = DateTime(2026, 7, 15); // a Wednesday

    testWidgets('renders every preset chip', (tester) async {
      await tester.pumpWidget(
        _host(
          DateRangeSelector(
            selected: DateRangePreset.thisMonth,
            onChanged: (_, __) {},
            now: now,
          ),
        ),
      );

      for (final preset in DateRangePreset.values) {
        expect(find.text(preset.label), findsOneWidget,
            reason: '${preset.label} chip should be present');
      }
    });

    testWidgets('tapping a preset reports its resolved span', (tester) async {
      DateRange? got;
      DateRangePreset? gotPreset;

      await tester.pumpWidget(
        _host(
          DateRangeSelector(
            selected: DateRangePreset.thisMonth,
            now: now,
            onChanged: (range, preset) {
              got = range;
              gotPreset = preset;
            },
          ),
        ),
      );

      await tester.tap(find.text('Current FY'));
      await tester.pump();

      expect(gotPreset, DateRangePreset.currentFy);
      expect(got!.start, DateTime(2026, 4, 1));
      expect(got!.contains(DateTime(2027, 3, 31)), isTrue);
    });

    testWidgets('Today resolves to a single day', (tester) async {
      DateRange? got;
      await tester.pumpWidget(
        _host(
          DateRangeSelector(
            selected: DateRangePreset.thisMonth,
            now: now,
            onChanged: (range, _) => got = range,
          ),
        ),
      );

      await tester.tap(find.text('Today'));
      await tester.pump();

      expect(got!.isSingleDay, isTrue);
    });
  });

  group('Fmt.range', () {
    test('collapses shared month and year', () {
      expect(
        Fmt.range(DateRange.month(DateTime(2026, 7))),
        '1 – 31 Jul 2026',
      );
      expect(Fmt.range(DateRange.day(DateTime(2026, 7, 15))), '15 Jul 2026');
      expect(
        Fmt.range(DateRange.spanning(DateTime(2026, 4, 1), DateTime(2027, 3, 31))),
        '1 Apr 2026 – 31 Mar 2027',
      );
    });
  });
}
