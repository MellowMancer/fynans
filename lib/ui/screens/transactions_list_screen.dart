import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_state.dart';
import 'package:fynans/entities/grouping_option.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/month_year_wheel_picker.dart';
import 'package:fynans/ui/widgets/transaction_list_widgets.dart';

enum ViewMode { simple, advanced }

/// How many years back the month pager reaches.
const int _kMonthsHistoryYears = 5;

/// Height of the month pager. It holds only the statement-period row, whose
/// height never varies, so the figures below it can size to their content —
/// that is what keeps swipe-to-change-month without leaving dead space.
const double _kMonthRowHeight = 52;

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  ViewMode _currentViewMode = ViewMode.simple;
  late final PageController _pageController;
  final List<DateTime> _months = [];
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _populateMonths();

    _currentPageIndex = _months.isNotEmpty ? _months.length - 1 : 0;
    _pageController = PageController(initialPage: _currentPageIndex);

    if (_months.isNotEmpty) {
      final initialMonth = _months[_currentPageIndex];
      context.read<TransactionCubit>().fetchTransactionsForMonth(initialMonth);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _populateMonths() {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - _kMonthsHistoryYears, now.month);
    var monthIterator = DateTime(firstDate.year, firstDate.month, 1);
    final lastMonth = DateTime(now.year, now.month, 1);
    while (!monthIterator.isAfter(lastMonth)) {
      _months.add(monthIterator);
      monthIterator = DateTime(monthIterator.year, monthIterator.month + 1, 1);
    }
  }

  Future<void> _editHierarchy(
    BuildContext context,
    AdvancedViewLoadSuccess state,
  ) async {
    final newHierarchy = await showDialog<List<GroupingOption>>(
      context: context,
      builder: (_) => _HierarchyEditorDialog(
        initialHierarchy: state.groupingHierarchy,
      ),
    );

    if (!context.mounted || newHierarchy == null || newHierarchy.isEmpty) return;
    context.read<AdvancedViewBloc>().add(
          AdvancedViewHierarchyChanged(newHierarchy),
        );
  }

  Future<void> _selectMonth() async {
    if (_months.isEmpty) return;

    final result = await MonthYearWheelPicker.show(
      context: context,
      initialDate: _months[_currentPageIndex],
      firstDate: _months.first,
      lastDate: _months.last,
    );
    if (result == null || !mounted) return;

    final targetIndex = _months.indexWhere(
      (m) => m.year == result.year && m.month == result.month,
    );
    if (targetIndex != -1) _pageController.jumpToPage(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isSimple = _currentViewMode == ViewMode.simple;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        tooltip: 'Add transaction',
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          _ViewModeSwitcher(
            mode: _currentViewMode,
            onChanged: (mode) => setState(() => _currentViewMode = mode),
          ),
          Expanded(
            // IndexedStack, not a conditional: swapping the subtree out
            // destroyed the month pager, and re-attaching rebuilt it from the
            // controller's initialPage — so returning to Simple snapped the
            // header back to the latest month while the list still showed the
            // month you had swiped to. Keeping both mounted also preserves
            // each view's scroll position.
            child: IndexedStack(
              index: isSimple ? 0 : 1,
              children: [
                _buildSimpleList(),
                _buildAdvancedList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // No refresh on return: both views hold live repository subscriptions, so the
  // save already pushes a new snapshot. Re-fetching here only tore down and
  // rebuilt the box watcher and flashed a loading state over data that arrived
  // on its own.
  void _openAddTransaction() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
      );

  /// The swipeable month row, plus the figures for the settled month. Only the
  /// row is paged; the figures below size to their content.
  Widget _buildSimpleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _kMonthRowHeight,
          child: PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            itemCount: _months.length,
            // The pager drives the simple view only; the advanced view picks
            // its own span with the range chips.
            onPageChanged: (index) {
              setState(() => _currentPageIndex = index);
              context
                  .read<TransactionCubit>()
                  .fetchTransactionsForMonth(_months[index]);
            },
            itemBuilder: (context, index) => StatementPeriodRow(
              month: _months[index],
              onSelectMonth: _selectMonth,
            ),
          ),
        ),
        AppSpacing.gapMd,
        const Divider(),
        AppSpacing.gapMd,
        BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) => SummaryBody(
            summary:
                state is TransactionLoadSuccess ? state.summary : null,
          ),
        ),
        AppSpacing.gapMd,
        const Divider(),
      ],
    );
  }

  /// Advanced header: a range card instead of the month pager.
  Widget _buildAdvancedHeader() {
    return BlocBuilder<AdvancedViewBloc, AdvancedViewState>(
      builder: (context, state) {
        if (state is! AdvancedViewLoadSuccess) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AppLoading(),
          );
        }
        return AdvancedSummaryCard(
          state: state,
          onEditHierarchy: _editHierarchy,
          onRangeChanged: (range, preset) => context
              .read<AdvancedViewBloc>()
              .add(AdvancedViewRangeChanged(range, preset)),
        );
      },
    );
  }

  Widget _buildSimpleList() {
    // Failure is rendered inside the list (see SimpleTransactionListView) so
    // the month pager stays mounted — it is the only control that can retrigger
    // a fetch, and unmounting it left the screen permanently dead.
    return SimpleTransactionListView(
      currentMonth: _months[_currentPageIndex],
      header: _buildSimpleHeader(),
    );
  }

  Widget _buildAdvancedList() {
    return BlocBuilder<AdvancedViewBloc, AdvancedViewState>(
      builder: (context, state) {
        if (state is AdvancedViewFailure) {
          return AppErrorView(
            title: 'Could not group transactions',
            message: state.error,
            onRetry: () =>
                context.read<AdvancedViewBloc>().add(AdvancedViewDataFetched()),
          );
        }
        if (state is AdvancedViewLoadSuccess) {
          // The header rides inside the list so it scrolls away with the
          // content instead of being pinned to the top.
          return HierarchicalTransactionList(
            nodes: state.hierarchicalData,
            summary: state.summary,
            header: _buildAdvancedHeader(),
          );
        }
        return const AppLoading();
      },
    );
  }
}

/// Simple/Advanced toggle, built from [AppPill] so it needs no bespoke
/// segmented-control widget.
class _ViewModeSwitcher extends StatelessWidget {
  const _ViewModeSwitcher({required this.mode, required this.onChanged});

  final ViewMode mode;
  final ValueChanged<ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppSegmented<ViewMode>(
          value: mode,
          onChanged: onChanged,
          segments: const [
            AppSegment(
              value: ViewMode.simple,
              label: 'Simple',
              icon: Icons.view_agenda_outlined,
            ),
            AppSegment(
              value: ViewMode.advanced,
              label: 'Advanced',
              icon: Icons.account_tree_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reorderable editor for the grouping hierarchy. Extracted from the screen so
/// the screen no longer hosts a 70-line dialog.
class _HierarchyEditorDialog extends StatefulWidget {
  const _HierarchyEditorDialog({required this.initialHierarchy});

  final List<GroupingOption> initialHierarchy;

  @override
  State<_HierarchyEditorDialog> createState() => _HierarchyEditorDialogState();
}

class _HierarchyEditorDialogState extends State<_HierarchyEditorDialog> {
  late final List<GroupingOption> _hierarchy = List.of(
    widget.initialHierarchy,
  );

  List<GroupingOption> get _unused =>
      GroupingOption.values.where((o) => !_hierarchy.contains(o)).toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Group transactions by'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionLabel('Drag to reorder'),
            AppSpacing.gapSm,
            Flexible(
              child: ReorderableListView(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                // onReorderItem hands back an index already adjusted for the
                // removed item, so no manual off-by-one fixup is needed.
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    _hierarchy.insert(newIndex, _hierarchy.removeAt(oldIndex));
                  });
                },
                children: [
                  for (var i = 0; i < _hierarchy.length; i++)
                    Padding(
                      key: ValueKey(_hierarchy[i]),
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 18,
                              color: context.colors.inkFaint,
                            ),
                          ),
                          AppSpacing.hGapSm,
                          MonoText.small('${i + 1}'),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              _hierarchy[i].displayName,
                              style: context.type.bodyStrong,
                            ),
                          ),
                          if (_hierarchy.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () =>
                                  setState(() => _hierarchy.removeAt(i)),
                              tooltip: 'Remove level',
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (_unused.isNotEmpty) ...[
              AppSpacing.gapMd,
              const AppSectionLabel('Add a level'),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final option in _unused)
                    AppPill(
                      option.displayName,
                      icon: Icons.add_rounded,
                      tone: AppPillTone.outline,
                      onTap: () => setState(() => _hierarchy.add(option)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          onPressed: () => Navigator.pop(context),
        ),
        AppButton(
          label: 'Apply',
          variant: AppButtonVariant.dark,
          size: AppButtonSize.sm,
          onPressed: _hierarchy.isEmpty
              ? null
              : () => Navigator.pop(context, _hierarchy),
        ),
      ],
    );
  }
}
