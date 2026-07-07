import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/blocs/transaction/transaction_state.dart';
import 'package:fynans/screens/add_transaction_screen.dart';
import 'package:fynans/widgets/transaction_list_widgets.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/widgets/month_year_wheel_picker.dart';

enum ViewMode { simple, advanced }

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends State<TransactionsListScreen> {
  ViewMode _currentViewMode = ViewMode.simple;
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
            padding: const EdgeInsets.all(8.0),
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
            height: _currentViewMode == ViewMode.simple ? 340.0 : 300.0,
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
                return _buildSummaryCard();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          Expanded(
            child: _currentViewMode == ViewMode.simple
                ? _buildMonthlyTransactionList()
                : _buildAdvancedHierarchicalView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_currentViewMode == ViewMode.simple) {
      return BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoadSuccess) {
            return SummaryCard(
              summary: state.summary,
              month: _months[_currentPageIndex],
              isSimpleMode: true,
              onSelectMonth: _selectMonth,
              onEditHierarchy: _editHierarchy,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return BlocBuilder<AdvancedViewBloc, AdvancedViewState>(
        builder: (context, state) {
          if (state is AdvancedViewLoadSuccess) {
            return SummaryCard(
              summary: state.summary,
              month: _months[_currentPageIndex],
              isSimpleMode: false,
              advancedState: state,
              onSelectMonth: _selectMonth,
              onEditHierarchy: _editHierarchy,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
  }

  Widget _buildMonthlyTransactionList() {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoadInProgress) {
          return const CircularProgressIndicator();
        }
        if (state is TransactionLoadFailure) {
          return Center(child: Text('Error: ${state.error}'));
        }
        if (state is TransactionLoadSuccess) {
          return SimpleTransactionListView(
            currentMonth: _months[_currentPageIndex],
          );
        }
        return const Center(child: Text('Initializing Simple View...'));
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
          return HierarchicalTransactionList(
            nodes: state.hierarchicalData,
            summary: state.summary,
          );
        }
        return const Center(child: Text('Initializing Advanced View...'));
      },
    );
  }
}
