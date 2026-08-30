import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/cards/cards_cubit.dart';
import 'package:fynans/adapters/blocs/cards/cards_state.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/card_tile.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/transaction_list_item.dart';

/// One card's summary and all-time transaction list.
///
/// Reads the [CardsCubit] provided by the pusher ([CardsScreen]) rather than
/// creating its own — one live subscription set per card, not two.
class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final int cardId;

  CardWithTransactions? _findCard(CardsState state) {
    if (state is! CardsLoadSuccess) return null;
    for (final c in state.cards) {
      if (c.summary.card.id == cardId) return c;
    }
    return null;
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
              : ListView(
                  padding: AppSpacing.pageInsets,
                  children: [
                    CardTile(summary: entry.summary),
                    AppSpacing.gapXl,
                    if (entry.transactions.isEmpty)
                      const AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions yet',
                        message: 'Card spends matched from SMS, or added '
                            'manually, will show up here.',
                      )
                    else
                      for (final t in entry.transactions)
                        TransactionListItem(
                          transaction: t,
                          margin: AppSpacing.rowGapInsets,
                        ),
                  ],
                ),
        );
      },
    );
  }
}
