import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_cubit.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_state.dart';
import 'package:fynans/entities/monthly_analytics.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/utils/tag_helper.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/month_year_wheel_picker.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';

/// Every Nth day gets an axis label on the daily chart.
const int _kAxisLabelInterval = 5;
const double _kChartHeight = 190;
const double _kPieDiameter = 148;

/// Axis with no labels — used for three of the bar chart's four sides.
const AxisTitles _hiddenAxis =
    AxisTitles(sideTitles: SideTitles(showTitles: false));

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalyticsCubit(
        GetMonthlyAnalytics(context.read<TransactionRepository>()),
      ),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatefulWidget {
  const _AnalyticsView();

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    context.read<AnalyticsCubit>().loadAnalytics(_selectedMonth);
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final picked = await MonthYearWheelPicker.show(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 5, now.month),
      lastDate: now,
    );
    if (picked == null || !mounted) return;

    setState(() => _selectedMonth = DateTime(picked.year, picked.month, 1));
    context.read<AnalyticsCubit>().loadAnalytics(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
            builder: (context, state) {
              if (state is AnalyticsLoadFailure) {
                return AppErrorView(
                  title: 'Could not load analytics',
                  message: state.error,
                );
              }
              if (state is! AnalyticsLoadSuccess) return const AppLoading();

              final analytics = state.analytics;
              if (analytics.totalOutflow == 0 && analytics.totalInflow == 0) {
                return const AppEmptyState(
                  icon: Icons.insights_outlined,
                  title: 'Nothing to chart yet',
                  message: 'Add or import transactions for this month to see '
                      'the breakdown.',
                );
              }

              return ListView(
                padding: AppSpacing.pageInsets,
                children: [
                  _FlowSummary(
                    analytics: analytics,
                    month: _selectedMonth,
                    onSelectMonth: _selectMonth,
                  ),
                  AppSpacing.gapCard,
                  _DailySpendingCard(
                    analytics: analytics,
                    month: _selectedMonth,
                  ),
                  AppSpacing.gapCard,
                  _SpendingByTagCard(analytics: analytics),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FlowSummary extends StatelessWidget {
  const _FlowSummary({
    required this.analytics,
    required this.month,
    required this.onSelectMonth,
  });

  final MonthlyAnalytics analytics;
  final DateTime month;
  final VoidCallback onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final net = analytics.totalInflow - analytics.totalOutflow;

    return AppCard(
      label: 'Statement Period',
      title: Fmt.monthYear(month),
      trailing: AppIconButton(
        icon: Icons.calendar_today_outlined,
        tooltip: 'Change month',
        onPressed: onSelectMonth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Inflow',
                  amount: analytics.totalInflow,
                  tone: MoneyTone.positive,
                  icon: Icons.south_west_rounded,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: AppMetricTile(
                  label: 'Outflow',
                  amount: analytics.totalOutflow,
                  tone: MoneyTone.negative,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          AppKeyValue(
            label: 'Net position',
            inline: true,
            valueWidget: MoneyText(
              net,
              tone: net < 0 ? MoneyTone.negative : MoneyTone.positive,
              style: context.type.amountSmall,
              signed: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySpendingCard extends StatelessWidget {
  const _DailySpendingCard({required this.analytics, required this.month});

  final MonthlyAnalytics analytics;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return AppCard(
      label: 'Outflow by day',
      title: 'Daily spending',
      child: SizedBox(
        height: _kChartHeight,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (var day = 1; day <= daysInMonth; day++)
                BarChartGroupData(
                  x: day,
                  barRods: [
                    BarChartRodData(
                      toY: analytics.dailySpending[day] ?? 0,
                      color: context.colors.accent,
                      width: 5,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ],
                ),
            ],
            titlesData: FlTitlesData(
              topTitles: _hiddenAxis,
              rightTitles: _hiddenAxis,
              leftTitles: _hiddenAxis,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    final day = value.toInt();
                    final isEdge = day == 1 || day == daysInMonth;
                    if (!isEdge && day % _kAxisLabelInterval != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: MonoText.small('$day'),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => context.colors.ink,
                // TextSpan can't go through MonoText, so the mono-is-upper-case
                // rule is applied to the string here.
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${Fmt.dayMonth(DateTime(month.year, month.month, group.x.toInt())).toUpperCase()}\n',
                  context.type.monoSmall.copyWith(color: context.colors.onAccent),
                  children: [
                    TextSpan(
                      text: Fmt.money(rod.toY),
                      style: context.type.amountSmall.copyWith(
                        color: context.colors.onAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpendingByTagCard extends StatelessWidget {
  const _SpendingByTagCard({required this.analytics});

  final MonthlyAnalytics analytics;

  /// One pie section.
  PieChartSectionData _section(BuildContext context, TagSlice slice) {
    final fill = context.tagColor(slice.label);
    return PieChartSectionData(
      color: fill,
      value: slice.amount,
      title: '${slice.percentage.toStringAsFixed(0)}%',
      radius: 26,
      titleStyle: context.type.monoSmall.copyWith(
        color: context.colors.inkOn(fill),
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slices = analytics.tagSlices;

    if (slices.isEmpty) {
      return AppCard(
        label: 'Where it went',
        title: 'Spending by tag',
        child: Text('No tagged spending yet.', style: context.type.small),
      );
    }

    return AppCard(
      label: 'Where it went',
      title: 'Spending by tag',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: _kPieDiameter,
            width: _kPieDiameter,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                sections: [
                  for (final slice in slices) _section(context, slice),
                ],
              ),
            ),
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final slice in slices)
                  AppAmountRow(
                    label: Fmt.capitalize(slice.label),
                    amount: slice.amount,
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.tagColor(slice.label),
                        borderRadius: AppRadius.pillAll,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
