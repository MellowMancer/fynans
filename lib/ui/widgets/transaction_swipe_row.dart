import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/add_transaction_screen.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/transaction_list_item.dart';
import 'package:fynans/ui/widgets/tag_icon_widget.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// The group of rows that close each other: when one row opens, the open row
/// closes. Needs a [SlidableAutoCloseBehavior] above the list.
const transactionSwipeGroup = 'transactions';

/// A transaction row whose card slides left, over three buttons: Edit,
/// Delete and Cancel. Delete asks for confirmation before it deletes the row.
///
/// The card slides past the page gutter and off the screen. The buttons lie
/// under the card, and join its rounded right edge without a gap.
class TransactionSwipeRow extends StatefulWidget {
  const TransactionSwipeRow({
    super.key,
    required this.transaction,
    this.overhang = AppSpacing.gutter,
    this.margin = AppSpacing.rowGapInsets,
  });

  final Transaction transaction;

  /// How far the slide area reaches left of the card. The card slides into
  /// this space: in the simple list it is the page gutter, so the card slides
  /// off the screen edge.
  final double overhang;

  /// The space around the slide area. It is outside the slide, so that the
  /// buttons are as tall as the card.
  final EdgeInsets margin;

  /// Shown if the repository cannot delete the row.
  static const deleteFailedMessage =
      'The transaction could not be deleted. Try again.';

  @override
  State<TransactionSwipeRow> createState() => _TransactionSwipeRowState();
}

class _TransactionSwipeRowState extends State<TransactionSwipeRow>
    with SingleTickerProviderStateMixin {
  /// The part of the slide area that the buttons cover when the row is open.
  static const _openExtent = 0.5;

  late final SlidableController _controller = SlidableController(this);

  Transaction get _transaction => widget.transaction;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final editColor = colors.accentSoft;

    return Padding(
      padding: widget.margin,
      child: Slidable(
        key: ValueKey(_transaction.id),
        controller: _controller,
        groupTag: transactionSwipeGroup,
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: _openExtent,
          children: [
            SlidableAction(
              onPressed: (_) => _edit(context),
              icon: Icons.edit_outlined,
              // label: 'Edit',
              backgroundColor: editColor,
              foregroundColor: colors.accentStrong,
            ),
            SlidableAction(
              onPressed: (_) => _confirmAndDelete(context),
              icon: Icons.delete_outline_rounded,
              // label: 'Delete',
              backgroundColor: colors.dangerSoft,
              foregroundColor: colors.danger,
            ),
            SlidableAction(
              // The action closes the row after any tap, so Cancel needs no
              // work of its own.
              onPressed: (_) {},
              icon: Icons.close_rounded,
              // label: 'Cancel',
              backgroundColor: colors.surfaceMuted,
              foregroundColor: colors.inkSecondary,
              // The right end of the buttons has the card's corners.
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppRadius.lg),
              ),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: AppRadius.lg,
              child: _CornerFill(controller: _controller, color: editColor),
            ),
            Padding(
              padding: EdgeInsets.only(left: widget.overhang),
              child: TransactionListItem(
                transaction: _transaction,
                margin: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddTransactionScreen(editing: _transaction),
        ),
      );

  Future<void> _confirmAndDelete(BuildContext context) async {
    final repository = context.read<TransactionRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDeleteDialog(transaction: _transaction),
    );
    if (confirmed != true) return;
    try {
      // The live list re-emits on the delete, so no refetch is needed.
      await repository.deleteTransaction(_transaction);
    } catch (_) {
      // Keep the message plain: the error text can contain SQL and the row.
      messenger.showSnackBar(
        const SnackBar(content: Text(TransactionSwipeRow.deleteFailedMessage)),
      );
    }
  }
}

/// Fills the two gaps under the card's rounded right corners with the Edit
/// colour, so that the card and Edit join without a gap. The slide shows the
/// buttons only right of the card's edge, so these gaps would otherwise show
/// the page. The fill lies under the card's right edge and moves with it. It
/// is hidden while the row is closed, because it would then show in the
/// card's corners.
class _CornerFill extends StatelessWidget {
  const _CornerFill({required this.controller, required this.color});

  final SlidableController controller;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller.animation,
        builder: (context, _) => controller.animation.value == 0
            ? const SizedBox.shrink()
            : ColoredBox(color: color),
      );
}

/// Asks the user to confirm the delete. Returns true to delete.
class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return AlertDialog(
      title: const Text('Delete this transaction?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The details in a card like the row that the user slid.
          AppCard(
            background: context.colors.surfaceMuted,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The same tone and sign as the row: green in, red out.
                MoneyText(
                  t.isInflow ? t.amount : -t.amount,
                  tone: t.isInflow ? MoneyTone.positive : MoneyTone.negative,
                  signed: t.isInflow,
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    // TagIconWidget(tags: t.tags),
                    // AppSpacing.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (t.party.trim().isNotEmpty)
                            Text(
                              t.party,
                              style: context.type.bodyStrong,
                              overflow: TextOverflow.ellipsis,
                            ),
                          AppSpacing.gapXxs,
                          MonoText.small(Fmt.fullDate(t.date)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          const Text('You cannot undo this.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: context.colors.danger),
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
