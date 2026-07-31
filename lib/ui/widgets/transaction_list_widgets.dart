import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_state.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/hierarchy_node.dart';
import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/filter_chips.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/utils/tag_helper.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ui/widgets/date_range_selector.dart';
import 'package:fynans/ui/widgets/transaction_filter_sheet.dart';
import 'package:fynans/ui/widgets/transaction_list_item.dart';
import 'package:fynans/use_cases/date_range_presets.dart';


/// Net position, with the inflow/outflow split revealed on tap.
///
/// Collapsed by default: the net figure answers "how did the period go?", and
/// the bifurcation is one tap away. Uses the same chevron + animated reveal as
/// a transaction row rather than a dropdown.
class TransactionTotals extends StatefulWidget {
  const TransactionTotals({
    super.key,
    required this.summary,
    this.initiallyExpanded = false,
  });

  final MonthlySummary summary;

  /// Start with the split already showing.
  final bool initiallyExpanded;

  @override
  State<TransactionTotals> createState() => _TransactionTotalsState();
}

class _TransactionTotalsState extends State<TransactionTotals> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final net = widget.summary.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: AppRadius.smAll,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSectionLabel('Net for this period'),
                    AppSpacing.gapXs,
                    MoneyText(
                      net,
                      tone: net < 0 ? MoneyTone.negative : MoneyTone.positive,
                      signed: true,
                      fit: true,
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapSm,
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: AppDuration.fast,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: context.colors.inkFaint,
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: AppDuration.normal,
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppMetricTile(
                          label: 'Inflow',
                          amount: widget.summary.totalIncome,
                          tone: MoneyTone.positive,
                          icon: Icons.south_west_rounded,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: AppMetricTile(
                          label: 'Outflow',
                          amount: widget.summary.totalExpenses,
                          tone: MoneyTone.negative,
                          icon: Icons.north_east_rounded,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Advanced header: pick a span with preset chips, then group and filter it.
class AdvancedSummaryCard extends StatelessWidget {
  const AdvancedSummaryCard({
    super.key,
    required this.state,
    required this.onRangeChanged,
    required this.onEditHierarchy,
  });

  final AdvancedViewLoadSuccess state;
  final void Function(DateRange range, DateRangePreset preset) onRangeChanged;
  final void Function(BuildContext, AdvancedViewLoadSuccess) onEditHierarchy;

  @override
  Widget build(BuildContext context) {
    return AppScreenHeader(
      label: 'Statement Period',
      title: Fmt.range(state.range),
      // The quick spans live behind this button, on the same row as the range
      // they set, instead of taking a whole chip row in the card.
      trailing: AppIconButton(
        icon: Icons.calendar_today_outlined,
        tooltip: 'Change date range',
        selected: state.preset.isCustom,
        onPressed: () => showDateRangeSheet(
          context: context,
          selected: state.preset,
          currentRange: state.range,
          onChanged: onRangeChanged,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TransactionTotals(summary: state.summary),
          AppSpacing.gapMd,
          const Divider(),
          AppSpacing.gapMd,
          AdvancedFilterControls(
            state: state,
            onEditHierarchy: onEditHierarchy,
          ),
        ],
      ),
    );
  }
}

/// The statement-period row: the month and its picker.
///
/// Deliberately the ONLY thing inside the month pager — it is constant height,
/// so the pager can be a small fixed box while the figures below it size to
/// their content. Each page renders its own month, so the label tracks the
/// drag instead of lagging until the page settles.
class StatementPeriodRow extends StatelessWidget {
  const StatementPeriodRow({
    super.key,
    required this.month,
    required this.onSelectMonth,
  });

  final DateTime month;
  final VoidCallback onSelectMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSectionLabel('Statement period'),
              AppSpacing.gapXxs,
              Text(Fmt.monthYear(month), style: context.type.h2),
            ],
          ),
        ),
        AppSpacing.hGapSm,
        AppIconButton(
          icon: Icons.calendar_today_outlined,
          tooltip: 'Change month',
          onPressed: onSelectMonth,
        ),
      ],
    );
  }
}

/// The selected month's figures: net (with the tap-revealed split) and top
/// spending. Sizes to its content — it lives outside the pager.
class SummaryBody extends StatelessWidget {
  const SummaryBody({super.key, required this.summary});

  /// Null while the month's figures are still loading.
  final MonthlySummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    if (summary == null) {
      return const SizedBox(height: 120, child: AppLoading());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TransactionTotals(summary: summary),
        AppSpacing.gapMd,
        const Divider(),
        AppSpacing.gapMd,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TopSpendingList(
                label: 'Top tags',
                spending: summary.topTags,
              ),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: TopSpendingList(
                label: 'Top groups',
                spending: summary.topGroups,
                showSwatch: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Grouping control plus a single filter entry point, with whatever is
/// currently applied shown as removable chips.
class AdvancedFilterControls extends StatelessWidget {
  const AdvancedFilterControls({
    super.key,
    required this.state,
    required this.onEditHierarchy,
  });

  final AdvancedViewLoadSuccess state;
  final void Function(BuildContext, AdvancedViewLoadSuccess) onEditHierarchy;

  @override
  Widget build(BuildContext context) {
    final filter = state.filter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSectionLabel('Grouped by'),
        AppSpacing.gapSm,
        AppButton(
          label: state.groupingHierarchy.map((e) => e.displayName).join('  ›  '),
          icon: Icons.account_tree_outlined,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.sm,
          onPressed: () => onEditHierarchy(context, state),
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            Expanded(
              child: AppSectionLabel(
                filter.isEmpty
                    ? 'Filters'
                    : 'Filters · ${filter.activeCount} active',
              ),
            ),
            AppButton(
              label: 'Filter',
              icon: Icons.tune_rounded,
              variant: filter.isEmpty
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.accent,
              size: AppButtonSize.sm,
              onPressed: () => _openFilterSheet(context),
            ),
          ],
        ),
        AppSpacing.gapSm,
        if (filter.isEmpty)
          MonoText.small('No filters applied')
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final chip in describeFilter(filter))
                AppPill(
                  chip.label,
                  icon: chip.icon,
                  tone: AppPillTone.accent,
                  onRemove: () => _apply(context, chip.clear(filter)),
                ),
            ],
          ),
      ],
    );
  }

  void _apply(BuildContext context, TransactionFilter filter) =>
      context.read<AdvancedViewBloc>().add(AdvancedViewFilterChanged(filter));

  Future<void> _openFilterSheet(BuildContext context) async {
    final repository = context.read<TransactionRepository>();
    final bloc = context.read<AdvancedViewBloc>();

    final options = FilterOptions(
      groups: await repository.getAllGroups()..sort(),
      tags: await repository.getAllUniqueTags()..sort(),
      parties: await repository.getAllParties()..sort(),
    );
    if (!context.mounted) return;

    final updated = await TransactionFilterSheet.show(
      context: context,
      filter: state.filter,
      options: options,
    );
    if (updated == null) return;
    bloc.add(AdvancedViewFilterChanged(updated));
  }
}

/// "Top tags" / "Top groups" breakdown.
class TopSpendingList extends StatelessWidget {
  const TopSpendingList({
    super.key,
    required this.label,
    required this.spending,
    this.showSwatch = true,
  });

  final String label;
  final Map<String, double> spending;

  /// Draw a per-tag colour dot before each row.
  final bool showSwatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionLabel(label),
        AppSpacing.gapXs,
        if (spending.isEmpty)
          const MonoText.small('Nothing yet')
        else
          for (final entry in spending.entries)
            AppAmountRow(
              label: Fmt.capitalize(entry.key),
              amount: entry.value,
              leading: showSwatch
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.tagColor(entry.key),
                        borderRadius: AppRadius.pillAll,
                      ),
                    )
                  : null,
            ),
      ],
    );
  }
}

/// Flat, date-ordered list for the simple view.
class SimpleTransactionListView extends StatelessWidget {
  const SimpleTransactionListView({
    super.key,
    required this.currentMonth,
    this.header,
  });

  final DateTime currentMonth;

  /// Scrolls away with the content rather than staying pinned.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<TransactionRepository>();

    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        final transactions =
            state is TransactionLoadSuccess ? state.transactions : null;
        final failure = state is TransactionLoadFailure ? state.error : null;
        final leading = header == null ? 0 : 1;

        // One body slot is used for the loading/empty placeholder so the header
        // stays on screen while the month reloads.
        final bodyCount =
            transactions == null || transactions.isEmpty ? 1 : transactions.length;

        return ListView.builder(
          padding: AppSpacing.pageInsets,
          itemCount: leading + bodyCount,
          itemBuilder: (context, index) {
            if (header != null && index == 0) {
              return Padding(
                padding: AppSpacing.headerGapInsets,
                child: header,
              );
            }

            if (failure != null) {
              // Rendered as a body row, not in place of the whole list, so the
              // month pager above stays mounted and can retrigger a fetch.
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: AppErrorView(
                  title: 'Could not load transactions',
                  message: failure,
                  onRetry: () => context
                      .read<TransactionCubit>()
                      .fetchTransactionsForMonth(currentMonth),
                ),
              );
            }
            if (transactions == null) {
              return const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxxl),
                child: AppLoading(),
              );
            }
            if (transactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxl),
                child: AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions this month',
                  message:
                      'Imported bank SMS and anything you add will appear here.',
                ),
              );
            }

            final transaction = transactions[index - leading];
            return Dismissible(
              key: ValueKey(transaction.key),
              direction: DismissDirection.endToStart,
              // The live subscription re-emits on the delete; no manual refetch.
              onDismissed: (_) => repository.deleteTransaction(transaction),
              background: Container(
                margin: AppSpacing.rowGapInsets,
                padding: const EdgeInsets.only(right: AppSpacing.xl),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: context.colors.dangerSoft,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: context.colors.dangerBorder),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: context.colors.danger,
                  size: 20,
                ),
              ),
              child: TransactionListItem(transaction: transaction),
            );
          },
        );
      },
    );
  }
}

/// Grouped tree for the advanced view.
class HierarchicalTransactionList extends StatelessWidget {
  const HierarchicalTransactionList({
    super.key,
    required this.nodes,
    required this.summary,
    this.header,
  });

  final List<HierarchyNode> nodes;
  final MonthlySummary summary;

  /// Scrolls away with the content rather than staying pinned.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final leading = header == null ? 0 : 1;

    return ListView.builder(
      padding: AppSpacing.pageInsets,
      itemCount: leading + (nodes.isEmpty ? 1 : nodes.length),
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return Padding(
            padding: AppSpacing.headerGapInsets,
            child: header,
          );
        }
        if (nodes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxxl),
            child: AppEmptyState(
              icon: Icons.filter_alt_outlined,
              title: 'Nothing matches these filters',
              message: 'Try clearing a filter or picking another range.',
            ),
          );
        }
        return HierarchyNodeTile(node: nodes[index - leading]);
      },
    );
  }
}

/// One node of the grouping tree; recurses for its children.
class HierarchyNodeTile extends StatelessWidget {
  const HierarchyNodeTile({super.key, required this.node, this.level = 0});

  final HierarchyNode node;
  final int level;

  @override
  Widget build(BuildContext context) {
    final isLeaf = node.children.isEmpty;
    final total = node.summary.total;

    final tile = Theme(
      // Strip the default expansion divider lines.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: node.children.length == 1,
        tilePadding: EdgeInsets.only(
          left: AppSpacing.md + (AppSpacing.md * level),
          right: AppSpacing.md,
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Fmt.capitalize(node.name),
                    style: context.type.bodyStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.gapXxs,
                  MonoText.small(
                    '${node.transactionCount} '
                    '${node.transactionCount == 1 ? "entry" : "entries"}',
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            MoneyText(
              total,
              tone: total < 0 ? MoneyTone.negative : MoneyTone.positive,
              style: context.type.amountSmall,
              signed: true,
            ),
          ],
        ),
        children: isLeaf
            ? [
                for (final t in node.transactions)
                  TransactionListItem(
                    transaction: t,
                    margin: EdgeInsets.only(
                      left: AppSpacing.md + (AppSpacing.md * level),
                      right: AppSpacing.md,
                      bottom: AppSpacing.rowGap,
                    ),
                  ),
              ]
            : [
                for (final child in node.children)
                  HierarchyNodeTile(node: child, level: level + 1),
              ],
      ),
    );

    // Only the outermost node gets a card shell, so nesting stays legible.
    if (level > 0) return tile;
    return AppCard(
      margin: AppSpacing.cardGapInsets,
      padding: EdgeInsets.zero,
      child: tile,
    );
  }
}
