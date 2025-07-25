import 'package:flutter/material.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/models/monthly_summary.dart';
import 'package:fynans/screens/add_transaction_screen.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:fynans/widgets/transaction_list_item.dart';
import 'package:intl/intl.dart';
import 'package:fynans/widgets/month_year_wheel_picker.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final HiveService _hiveService = HiveService();
  late final PageController _pageController;
  final List<DateTime> _months = [];
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _populateMonths();
    
    _currentPageIndex = _months.length - 1;
    _pageController = PageController(
      initialPage: _currentPageIndex >= 0 ? _currentPageIndex : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_months.isEmpty) {
      return Scaffold(
        // appBar: AppBar(title: const Text('Monthly Overview')),
        body: const Center(child: Text('No data available.')),
      );
    }
    final selectedMonth = _months[_currentPageIndex];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _months.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildSummaryCard(_months[index]);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(height: 1),
          ),
          Expanded(child: _buildMonthlyTransactionList(selectedMonth)),
        ],
      ),
    );
  }

  void _populateMonths() {
    final now = DateTime.now();
    // Create a date range of 5 years back from the current month.
    final firstDate = DateTime(now.year - 5, now.month);

    DateTime monthIterator = DateTime(firstDate.year, firstDate.month, 1);
    final lastMonth = DateTime(now.year, now.month, 1);

    while (monthIterator.isBefore(lastMonth) ||
        monthIterator.isAtSameMomentAs(lastMonth)) {
      _months.add(monthIterator);
      // This safely increments the month, handling year rollovers.
      monthIterator = DateTime(monthIterator.year, monthIterator.month + 1, 1);
    }
  }

  void _selectMonth() async {
    if (_months.isEmpty) return;

    final result = await MonthYearWheelPicker.show(
      context: context,
      initialDate: _months[_currentPageIndex],
      firstDate: _months.first,
      lastDate: _months.last,
    );

    if (result != null && mounted) {
      final targetMonth = DateTime(result.year, result.month, 1);
      final targetIndex = _months.indexWhere(
        (month) =>
            month.year == targetMonth.year && month.month == targetMonth.month,
      );

      if (targetIndex != -1) {
        _pageController.jumpToPage(targetIndex);
      }
    }
  }

  Widget _buildSummaryCard(DateTime month) {
    return StreamBuilder<List<Transaction>>(
      stream: _hiveService.listenToTransactionsForMonth(month: month),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final summary = MonthlySummary.fromTransactions(snapshot.data!);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM().format(month),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectMonth,
                      tooltip: 'Select Month',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFlowIndicator(
                      context,
                      title: 'Inflow',
                      amount: summary.totalIncome,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(width: 8),
                    _buildFlowIndicator(
                      context,
                      title: 'Outflow',
                      amount: summary.totalTransactions,
                      color: Colors.red.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      _buildTopSpendingList('Top Tags', summary.topTags),
                      const VerticalDivider(width: 24),
                      _buildTopSpendingList('Top Groups', summary.topGroups),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlowIndicator(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 45, 45, 45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSpendingList(String title, Map<String, double> spending) {
    String capitalize(String s) =>
        s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (spending.isEmpty)
            const Text('None', style: TextStyle(fontStyle: FontStyle.italic))
          else
            Expanded(
              child: ListView(
                children: spending.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                capitalize(entry.key),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('₹${entry.value.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTransactionList(DateTime month) {
    return StreamBuilder<List<Transaction>>(
      stream: _hiveService.listenToTransactionsForMonth(month: month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No transactions for this month.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Dismissible(
              key: ValueKey(transaction.key),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                _hiveService.deleteTransaction(transaction.key);
              },
              background: Container(
                color: Colors.red.shade800,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: TransactionListItem(transaction: transaction),
            );
          },
        );
      },
    );
  }
}
