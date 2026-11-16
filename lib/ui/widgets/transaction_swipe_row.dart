import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/transaction_list_item.dart';

/// The group of rows that close each other: when one row opens, the open row
/// closes. Needs a [SlidableAutoCloseBehavior] above the list.
const transactionSwipeGroup = 'transactions';

/// A transaction row that slides left and stops with three buttons: Edit,
/// Delete and Cancel. Delete asks for confirmation before it deletes the row.
class TransactionSwipeRow extends StatelessWidget {
  const TransactionSwipeRow({super.key, required this.transaction});

  final Transaction transaction;

  /// The part of the row that the buttons cover when the row is open.
  static const _openExtent = 0.75;

  /// Shown if the repository cannot delete the row.
  static const deleteFailedMessage =
      'The transaction could not be deleted. Try again.';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The gap below the row sits outside the slide, so that the buttons are
    // as tall as the card. The clip gives the card and the buttons the same
    // rounded corners, so that they read as one shape.
    return Padding(
      padding: AppSpacing.rowGapInsets,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Slidable(
          key: ValueKey(transaction.id),
          groupTag: transactionSwipeGroup,
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: _openExtent,
            children: [
              SlidableAction(
                onPressed: (_) => _edit(context),
                icon: Icons.edit_outlined,
                label: 'Edit',
                backgroundColor: colors.accentSoft,
                foregroundColor: colors.accentStrong,
              ),
              SlidableAction(
                onPressed: (_) => _confirmAndDelete(context),
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                backgroundColor: colors.dangerSoft,
                foregroundColor: colors.danger,
              ),
              SlidableAction(
                // The action closes the row after any tap, so Cancel needs no
                // work of its own.
                onPressed: (_) {},
                icon: Icons.close_rounded,
                label: 'Cancel',
                backgroundColor: colors.surfaceMuted,
                foregroundColor: colors.inkSecondary,
              ),
            ],
          ),
          child: TransactionListItem(
            transaction: transaction,
            margin: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  void _edit(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddTransactionScreen(editing: transaction),
        ),
      );

  Future<void> _confirmAndDelete(BuildContext context) async {
    final repository = context.read<TransactionRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDeleteDialog(transaction: transaction),
    );
    if (confirmed != true) return;
    try {
      // The live list re-emits on the delete, so no refetch is needed.
      await repository.deleteTransaction(transaction);
    } catch (_) {
      // Keep the message plain: the error text can contain SQL and the row.
      messenger.showSnackBar(
        const SnackBar(content: Text(deleteFailedMessage)),
      );
    }
  }
}

/// Asks the user to confirm the delete. Returns true to delete.
class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final summary = [
      if (t.party.trim().isNotEmpty) t.party,
      Fmt.money(t.amount),
      Fmt.fullDate(t.date),
    ].join('  ·  ');
    return AlertDialog(
      title: const Text('Delete this transaction?'),
      content: Text('$summary\n\nYou cannot undo this.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: context.colors.danger),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
