import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/cards/cards_cubit.dart';
import 'package:fynans/adapters/blocs/cards/cards_state.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/card_tile.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/month_year_wheel_picker.dart';
import 'package:fynans/ui/widgets/payment_due_banner.dart';
import 'package:fynans/ui/widgets/transaction_list_item.dart';
import 'package:fynans/ui/widgets/transaction_list_widgets.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';

/// How far back the month picker reaches — matches Expenses' own pager.
const int _kMonthsHistoryYears = 5;

/// One card's all-time summary plus a month-scoped transaction list.
///
/// Available/spent/utilization stay all-time — a credit limit is a running
/// balance, not something that resets monthly, so that figure has to stay
/// primary. The month picker below it is a separate lens: "what did I spend
/// on this card in July", the same question Expenses answers for the main
/// list.
///
/// Reads the [CardsCubit] provided by the pusher ([CardsScreen]) rather than
/// creating its own — one live subscription set per card, not two.
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final int cardId;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  DateTime _selectedMonth = DateTime.now();

  CardWithTransactions? _findCard(CardsState state) {
    if (state is! CardsLoadSuccess) return null;
    for (final c in state.cards) {
      if (c.summary.card.id == widget.cardId) return c;
    }
    return null;
  }

  List<Transaction> _transactionsForSelectedMonth(List<Transaction> all) {
    final range = DateRange.month(_selectedMonth);
    return all.where((t) => range.contains(t.date)).toList();
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final result = await MonthYearWheelPicker.show(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - _kMonthsHistoryYears, now.month),
      lastDate: DateTime(now.year, now.month),
    );
    if (result != null && mounted) {
      setState(() => _selectedMonth = DateTime(result.year, result.month));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, CreditCard card, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${card.issuer} •••• ${card.last4}?'),
        content: Text(
          count == 0
              ? 'This card has no transactions yet.'
              : 'Its $count transaction${count == 1 ? '' : 's'} will move back '
                  'into your main Expenses list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final id = card.id;
    if (id == null) return;

    // Read both before the next await — a BuildContext lookup is a
    // synchronous tree walk, so doing it now (rather than after unlinkCard
    // completes) avoids using context past a second await gap.
    final transactionRepository = context.read<TransactionRepository>();
    final cardRepository = context.read<CardRepository>();

    // Unlink first: if delete succeeded but unlink failed, the transactions
    // would be orphaned under a card_id that no longer exists.
    await transactionRepository.unlinkCard(id);
    await cardRepository.deleteCard(card);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardsCubit, CardsState>(
      builder: (context, state) {
        final entry = _findCard(state);

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 68,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSectionLabel(
                  entry?.summary.card.issuer ?? 'Card',
                  color: context.colors.accent,
                ),
                AppSpacing.gapXxs,
                Text(
                  entry == null ? '' : '•••• ${entry.summary.card.last4}',
                  style: context.type.h1,
                ),
              ],
            ),
            actions: entry == null
                ? null
                : [
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: context.colors.danger),
                      tooltip: 'Delete card',
                      onPressed: () => _confirmDelete(
                        context,
                        entry.summary.card,
                        entry.transactions.length,
                      ),
                    ),
                    AppSpacing.hGapSm,
                  ],
          ),
          floatingActionButton: entry == null
              ? null
              : FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddTransactionScreen(card: entry.summary.card),
                    ),
                  ),
                  tooltip: 'Add transaction',
                  child: const Icon(Icons.add_rounded),
                ),
          body: entry == null
              ? const AppLoading()
              : _CardDetailBody(
                  entry: entry,
                  selectedMonth: _selectedMonth,
                  monthTransactions: _transactionsForSelectedMonth(
                    entry.transactions,
                  ),
                  onSelectMonth: _selectMonth,
                ),
        );
      },
    );
  }
}

class _CardDetailBody extends StatelessWidget {
  const _CardDetailBody({
    required this.entry,
    required this.selectedMonth,
    required this.monthTransactions,
    required this.onSelectMonth,
  });

  final CardWithTransactions entry;
  final DateTime selectedMonth;
  final List<Transaction> monthTransactions;
  final VoidCallback onSelectMonth;

  @override
  Widget build(BuildContext context) {
    // Spent this month only — never available/utilization, which stay
    // all-time on the CardTile above.
    final monthSpent = summariseTransactions(monthTransactions).totalExpenses;

    return ListView(
      padding: AppSpacing.pageInsets,
      children: [
        CardTile(summary: entry.summary),
        if (entry.latestStatement != null) ...[
          AppSpacing.gapMd,
          PaymentDueBanner(statement: entry.latestStatement),
        ],
        AppSpacing.gapXl,
        StatementPeriodRow(month: selectedMonth, onSelectMonth: onSelectMonth),
        AppSpacing.gapMd,
        AppMetricTile(
          label: 'Spent this month',
          amount: monthSpent,
          tone: MoneyTone.negative,
        ),
        AppSpacing.gapMd,
        const Divider(),
        AppSpacing.gapMd,
        if (monthTransactions.isEmpty)
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: entry.transactions.isEmpty
                ? 'No transactions yet'
                : 'No transactions this month',
            message: entry.transactions.isEmpty
                ? 'Card spends matched from SMS, or added manually, will '
                    'show up here.'
                : 'Nothing on this card in ${Fmt.monthYear(selectedMonth)}.',
          )
        else
          for (final t in monthTransactions)
            TransactionListItem(
              transaction: t,
              margin: AppSpacing.rowGapInsets,
            ),
      ],
    );
  }
}
