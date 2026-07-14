import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_cubit.dart';
import 'package:fynans/adapters/blocs/analytics/analytics_state.dart';
import 'package:fynans/entities/monthly_analytics.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';
import 'package:fynans/ui/utils/tag_helper.dart';
import 'package:intl/intl.dart';
import 'package:fynans/ui/widgets/month_year_wheel_picker.dart';


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
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    context.read<AnalyticsCubit>().loadAnalytics(_selectedMonth);
  }

  void _selectMonth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month);
    final pickedDate = await MonthYearWheelPicker.show(
      context: context,
      initialDate: _selectedMonth,
      firstDate: firstDate,
      lastDate: now,
    );

    if (!mounted) return;

    if (pickedDate != null) {
      setState(() {
        _selectedMonth = DateTime(pickedDate.year, pickedDate.month, 1);
      });
      context.read<AnalyticsCubit>().loadAnalytics(_selectedMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      DateFormat.yMMMM().format(_selectedMonth),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    onPressed: _selectMonth,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoadFailure) {
                  return Center(child: Text('Error: ${state.error}'));
                }
                if (state is! AnalyticsLoadSuccess) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.analytics.totalOutflow == 0) {
                  return const Center(child: Text('No data for this month.'));
                }

                final analytics = state.analytics;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInOutFlowCards(analytics),
                      const SizedBox(height: 24),
                      _buildDailySpendingChart(context, analytics),
                      const SizedBox(height: 24),
                      _buildSpendingByTagChart(context, analytics),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInOutFlowCards(MonthlyAnalytics analytics) {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Inflow',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${analytics.totalInflow.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Outflow',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red.shade300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${analytics.totalOutflow.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySpendingChart(BuildContext context, MonthlyAnalytics analytics) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final barGroups = List.generate(daysInMonth, (index) {
      final day = index + 1;
      final spending = analytics.dailySpending[day] ?? 0;
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: spending,
            color: Theme.of(context).colorScheme.primary,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Spending', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 5 == 0 || value.toInt() == 1 || value.toInt() == daysInMonth) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      'Day ${group.x.toInt()}\n',
                      const TextStyle(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: '₹${rod.toY.toStringAsFixed(2)}'),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingByTagChart(BuildContext context, MonthlyAnalytics analytics) {
    final slices = analytics.tagSlices;

    final pieChartSections = slices.map((slice) {
      const fontSize = 14.0;
      const radius = 50.0;

      return PieChartSectionData(
        color: TagHelper.getColorForTag(slice.label),
        value: slice.amount,
        title: '${slice.percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spending by Tag', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: PieChart(PieChartData(sections: pieChartSections, centerSpaceRadius: 40)),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: slices.map((slice) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, color: TagHelper.getColorForTag(slice.label)),
                        const SizedBox(width: 8),
                        Text(slice.label[0].toUpperCase() + slice.label.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
