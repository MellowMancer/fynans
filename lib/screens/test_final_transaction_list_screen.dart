// screens/test_transactions_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/blocs/transaction/transaction_state.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/screens/add_transaction_screen.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:fynans/widgets/transaction_list_item.dart';
import 'package:intl/intl.dart';
import 'package:fynans/models/monthly_summary.dart';
import 'package:fynans/widgets/month_year_wheel_picker.dart';

// Enum to manage which view is currently shown
enum ViewMode { simple, advanced }

class TestTransactionsListScreen extends StatefulWidget {
  const TestTransactionsListScreen({super.key});

  @override
  State<TestTransactionsListScreen> createState() =>
      _TestTransactionsListScreenState();
}

class _TestTransactionsListScreenState
    extends State<TestTransactionsListScreen> {
  ViewMode _currentViewMode = ViewMode.simple;
  final HiveService _hiveService = HiveService();
  late final PageController _pageController;
  final List<DateTime> _months = [];
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _populateMonths();

    _currentPageIndex = _months.isNotEmpty ? _months.length - 1 : 0;
    _pageController = PageController(
      initialPage: _currentPageIndex >= 0 ? _currentPageIndex : 0,
    );

    if (_months.isNotEmpty) {
      final initialMonth = _months[_currentPageIndex];
      context.read<TransactionCubit>().fetchTransactionsForMonth(initialMonth);
      context
          .read<AdvancedViewBloc>()
          .add(AdvancedViewMonthChanged(initialMonth));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _populateMonths() {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month);
    DateTime monthIterator = DateTime(firstDate.year, firstDate.month, 1);
    final lastMonth = DateTime(now.year, now.month, 1);
    while (monthIterator.isBefore(lastMonth) ||
        monthIterator.isAtSameMomentAs(lastMonth)) {
      _months.add(monthIterator);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          ).then((_) {
            if (!context.mounted) return;

            final now = DateTime.now();
            context.read<TransactionCubit>().fetchTransactionsForMonth(now);
            context.read<AdvancedViewBloc>().add(AdvancedViewDataFetched());
          });
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: SegmentedButton<ViewMode>(
              segments: const <ButtonSegment<ViewMode>>[
                ButtonSegment<ViewMode>(
                    value: ViewMode.simple,
                    label: Text('Simple'),
                    icon: Icon(Icons.list)),
                ButtonSegment<ViewMode>(
                    value: ViewMode.advanced,
                    label: Text('Advanced'),
                    icon: Icon(Icons.account_tree)),
              ],
              selected: {_currentViewMode},
              onSelectionChanged: (Set<ViewMode> newSelection) {
                setState(() {
                  _currentViewMode = newSelection.first;
                });
              },
            ),
          ),
          SizedBox(
            height: _currentViewMode == ViewMode.simple ? 320.0 : 280.0,
            child: PageView.builder(
              controller: _pageController,
              physics: _currentViewMode == ViewMode.advanced
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: _months.length,
              onPageChanged: (index) {
                setState(() => _currentPageIndex = index);
                final newMonth = _months[index];

                context
                    .read<TransactionCubit>()
                    .fetchTransactionsForMonth(newMonth);
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
          // --- DYNAMIC CONTENT BASED ON VIEW MODE ---
          Expanded(
            child: _currentViewMode == ViewMode.simple
                ? _buildMonthlyTransactionList()
                : _buildAdvancedHierarchicalView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DateTime month) {
    if (_currentViewMode == ViewMode.simple) {
      // In simple mode, listen to TransactionCubit
      return BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoadSuccess) {
            return _buildCardContent(context,
                month: month, summary: state.summary, state: 'simple');
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      // In advanced mode, listen to AdvancedViewBloc
      return BlocBuilder<AdvancedViewBloc, AdvancedViewState>(
        builder: (context, state) {
          if (state is AdvancedViewLoadSuccess) {
            return _buildCardContent(context,
                month: month, summary: state.summary, state: 'advanced');
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
  }

  /// The actual UI for the card. It's now separate and just takes data.
  Widget _buildCardContent(BuildContext context,
      {required DateTime month,
      required MonthlySummary summary,
      required String state}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Title
            if (state == 'simple')
              (Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat.yMMMM().format(month),
                        style: Theme.of(context).textTheme.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectMonth,
                      tooltip: 'Select Month',
                    ),
                  ])),
            const SizedBox(height: 12),
            // Inflow/Outflow Indicators
            Row(
              children: [
                _buildFlowIndicator(context,
                    title: 'Inflow',
                    amount: summary.totalIncome,
                    color: Colors.green.shade300),
                const SizedBox(width: 8),
                _buildFlowIndicator(context,
                    title: 'Outflow',
                    amount: summary.totalTransactions,
                    color: Colors.red.shade300),
              ],
            ),

            if (state == 'simple')
              ...([
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                // Top Tags/Groups
                Expanded(
                  child: Row(
                    children: [
                      _buildTopSpendingList('Top Tags', summary.topTags),
                      const VerticalDivider(width: 24),
                      _buildTopSpendingList('Top Groups', summary.topGroups),
                    ],
                  ),
                ),
              ])
            else
              ...([
                _buildFilterControls(
                    context,
                    AdvancedViewLoadSuccess(
                        selectedMonth: month,
                        groupingHierarchy: [],
                        filterGroup: null,
                        filterTag: null,
                        filterParty: null,
                        hierarchicalData: [],
                        summary: summary))
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowIndicator(BuildContext context,
      {required String title, required double amount, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 45, 45),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.white70)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('₹${amount.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSpendingList(String title, Map<String, double> spending) {
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
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(_capitalize(entry.key),
                                      overflow: TextOverflow.ellipsis)),
                              Text('₹${entry.value.toStringAsFixed(0)}'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTransactionList() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoadInProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TransactionLoadFailure) {
          return Center(child: Text('Error: ${state.error}'));
        }
        if (state is TransactionLoadSuccess) {
          if (state.transactions.isEmpty) {
            return const Center(child: Text('No transactions for this month.'));
          }
          final transactions = state.transactions;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Dismissible(
                key: ValueKey(transaction.key),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  _hiveService.deleteTransaction(transaction.key).then((_) {
                    // --- REFETCH ON DELETE ---
                    if (!context.mounted) return;
                    context
                        .read<TransactionCubit>()
                        .fetchTransactionsForMonth(_months[_currentPageIndex]);
                  });
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
        }
        return const SizedBox.shrink(); // Fallback for initial state
      },
    );
  }

  Widget _buildAdvancedHierarchicalView() {
    return BlocBuilder<AdvancedViewBloc, AdvancedViewState>(
      builder: (context, state) {
        if (state is AdvancedViewLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdvancedViewFailure) {
          return Center(child: Text('Error: ${state.error}'));
        }
        if (state is AdvancedViewLoadSuccess) {
          // The main layout for the advanced view
          return Column(
            children: [
              // _buildFilterControls(context, state),
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          );
        }
        return const Center(child: Text('Initializing Advanced View...'));
      },
    );
  }

  /// Builds the top-level controls for month selection and hierarchy editing.
  Widget _buildFilterControls(
      BuildContext context, AdvancedViewLoadSuccess state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionChip(
            avatar: const Icon(Icons.sort, size: 16),
            label: Text(
              state.groupingHierarchy.map((e) => e.displayName).join(' > '),
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => _editHierarchy(context, state),
            tooltip: 'Edit Grouping Hierarchy',
          ),
          _buildAdvancedFilters(context, state)
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(
      BuildContext context, AdvancedViewLoadSuccess state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.end,
        children: [
          _buildFilterChip(
            context: context,
            label: 'Group',
            value: state.filterGroup,
            onPressed: () => _showFilterSelectionDialog(
              context: context,
              title: 'Filter by Group',
              itemsFuture: _hiveService.getAllGroups(),
              onSelected: (value) => context
                  .read<AdvancedViewBloc>()
                  .add(AdvancedViewGroupFilterChanged(value)),
            ),
            onDeleted: () => context
                .read<AdvancedViewBloc>()
                .add(AdvancedViewGroupFilterChanged(null)),
          ),
          _buildFilterChip(
            context: context,
            label: 'Tag',
            value: state.filterTag,
            onPressed: () => _showFilterSelectionDialog(
              context: context,
              title: 'Filter by Tag',
              itemsFuture: _hiveService.getAllUniqueTags(),
              onSelected: (value) => context
                  .read<AdvancedViewBloc>()
                  .add(AdvancedViewTagFilterChanged(value)),
            ),
            onDeleted: () => context
                .read<AdvancedViewBloc>()
                .add(AdvancedViewTagFilterChanged(null)),
          ),
          _buildFilterChip(
            context: context,
            label: 'Party',
            value: state.filterParty,
            onPressed: () => _showFilterSelectionDialog(
              context: context,
              title: 'Filter by Party',
              itemsFuture: _hiveService.getAllParties(),
              onSelected: (value) => context
                  .read<AdvancedViewBloc>()
                  .add(AdvancedViewPartyFilterChanged(value)),
            ),
            onDeleted: () => context
                .read<AdvancedViewBloc>()
                .add(AdvancedViewPartyFilterChanged(null)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String? value,
    required VoidCallback onPressed,
    required VoidCallback onDeleted,
  }) {
    return FilterChip(
      label: Text(value != null ? '$label: ${_capitalize(value)}' : label),
      selected: value != null,
      onSelected: (_) => onPressed(),
      onDeleted: value != null ? onDeleted : null,
    );
  }

  /// Builds the main content area with the total card and the hierarchical list.
  Widget _buildContent(BuildContext context, AdvancedViewLoadSuccess state) {
    if (state.hierarchicalData.isEmpty) {
      return const Center(
          child: Text('No transactions found for this selection.'));
    }

    return ListView.builder(
      itemCount: state.hierarchicalData.length + 1, // +1 for the total card
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('Total For Selection'),
              trailing: Text('₹${state.summary.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          );
        }
        return _buildHierarchyNodeTile(state.hierarchicalData[index - 1],
            level: 0);
      },
    );
  }

  /// Recursively builds ExpansionTiles for the hierarchy.
  Widget _buildHierarchyNodeTile(HierarchyNode node, {required int level}) {
    // A node is a leaf if it has no children, in which case we show its transactions.
    final isLeafNode = node.children.isEmpty;

    // Add padding to the left to create the indentation effect.
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * level),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(_capitalize(node.name),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text('₹${node.summary.total.toStringAsFixed(2)}'),
            ),
          ],
        ),
        initiallyExpanded: node.children.length ==
            1, // Auto-expand if there's only one sub-group
        children: isLeafNode
            ? node.transactions
                .map((e) => TransactionListItem(transaction: e))
                .toList()
            : node.children
                .map(
                    (child) => _buildHierarchyNodeTile(child, level: level + 1))
                .toList(),
      ),
    );
  }

  // --- UI Action Handlers ---

  /// Shows a dialog to edit the grouping hierarchy and dispatches an event.
  void _editHierarchy(
      BuildContext context, AdvancedViewLoadSuccess state) async {
    final newHierarchy = await showDialog<List<GroupingOption>>(
      context: context,
      builder: (context) {
        final availableOptions = GroupingOption.values.toList();
        List<GroupingOption> tempHierarchy = List.from(state.groupingHierarchy);

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Grouping Hierarchy'),
            content: SizedBox(
              width: double.maxFinite,
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = tempHierarchy.removeAt(oldIndex);
                    tempHierarchy.insert(newIndex, item);
                  });
                },
                children: [
                  for (int i = 0; i < tempHierarchy.length; i++)
                    ListTile(
                      key: ValueKey(tempHierarchy[i]),
                      title: Text('${i + 1}. ${tempHierarchy[i].displayName}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () =>
                            setState(() => tempHierarchy.removeAt(i)),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              // Show dropdown to add a new level if not all options are used
              if (tempHierarchy.length < GroupingOption.values.length)
                DropdownButton<GroupingOption>(
                  hint: const Text('Add level...'),
                  items: availableOptions
                      .where((o) => !tempHierarchy.contains(o))
                      .map((option) => DropdownMenuItem(
                          value: option, child: Text(option.displayName)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => tempHierarchy.add(value));
                  },
                ),
              const Spacer(),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, tempHierarchy),
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );

    if (context.mounted && newHierarchy != null && newHierarchy.isNotEmpty) {
      context
          .read<AdvancedViewBloc>()
          .add(AdvancedViewHierarchyChanged(newHierarchy));
    }
  }

  /// Generic dialog to select a filter value from a list.
  void _showFilterSelectionDialog({
    required BuildContext context,
    required String title,
    required Future<List<String>> itemsFuture,
    required void Function(String?) onSelected,
  }) async {
    final items = await itemsFuture;
    if (!context.mounted) return;

    items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectedValue = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Clear Filter',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.red)),
          ),
          ...items.map((item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item),
                child: Text(_capitalize(item)),
              )),
        ],
      ),
    );

    if (context.mounted) {
      onSelected(selectedValue);
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
}
