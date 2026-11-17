import 'package:flutter/material.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/card_status_text.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/use_cases/remove_card.dart';

/// The choice that [RemoveCardDialog] returns.
class CardRetirement {
  const CardRetirement(this.status, this.closingDate);

  /// [CardStatus.closed] or [CardStatus.untracked].
  final CardStatus status;

  /// The closing date. Only a closed card uses it.
  final DateTime closingDate;
}

/// Lets the user close or untrack a card that has history. Each option shows
/// how many of the card's transactions it hides.
class RemoveCardDialog extends StatefulWidget {
  const RemoveCardDialog({
    super.key,
    required this.card,
    required this.transactions,
    required this.firstClosingDate,
  });

  final PaymentCard card;

  /// All of the card's transactions, for the live counts.
  final List<Transaction> transactions;

  /// The earliest closing date that the date picker offers.
  final DateTime firstClosingDate;

  /// Shows the dialog. Returns null if the user cancels.
  static Future<CardRetirement?> show(
    BuildContext context, {
    required PaymentCard card,
    required List<Transaction> transactions,
    required DateTime firstClosingDate,
  }) =>
      showDialog<CardRetirement>(
        context: context,
        builder: (_) => RemoveCardDialog(
          card: card,
          transactions: transactions,
          firstClosingDate: firstClosingDate,
        ),
      );

  @override
  State<RemoveCardDialog> createState() => _RemoveCardDialogState();
}

class _RemoveCardDialogState extends State<RemoveCardDialog> {
  CardStatus _status = CardStatus.closed;
  DateTime _closingDate = DateTime.now();

  Future<void> _pickClosingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _closingDate,
      firstDate: widget.firstClosingDate,
      lastDate: DateTime.now(),
      helpText: 'Closing date',
    );
    if (picked != null && mounted) setState(() => _closingDate = picked);
  }

  String _hides(CardStatus status) {
    final hidden =
        HiddenTransactions.of(widget.transactions, status, _closingDate);
    return 'Hides ${hiddenTransactionsText(hidden)}.';
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.transactions.length;
    return AlertDialog(
      title: Text('Remove ${cardName(widget.card)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count == 0
                ? 'This card has statements, so it cannot be deleted.'
                : 'This card has ${transactionCountText(count)}, so it '
                    'cannot be deleted.'),
            AppSpacing.gapMd,
            _Option(
              selected: _status == CardStatus.closed,
              title: 'Close this card',
              description: "Stops counting this card's transactions after "
                  'the closing date.',
              onTap: () => setState(() => _status = CardStatus.closed),
              details: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Closing date: ${Fmt.fullDate(_closingDate)}',
                        style: context.type.small,
                      ),
                    ),
                    TextButton(
                      onPressed: _pickClosingDate,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                Text(_hides(CardStatus.closed), style: context.type.small),
              ],
            ),
            AppSpacing.gapSm,
            _Option(
              selected: _status == CardStatus.untracked,
              title: 'Untrack this card',
              description: "Stops counting all of this card's transactions "
                  'in your finances.',
              onTap: () => setState(() => _status = CardStatus.untracked),
              details: [
                Text(_hides(CardStatus.untracked), style: context.type.small),
              ],
            ),
            AppSpacing.gapMd,
            const Text('You can restore the card later from the Cards page.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, CardRetirement(_status, _closingDate)),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}

/// One choice in the dialog: a radio mark, a title, what it does, and its
/// live details.
class _Option extends StatelessWidget {
  const _Option({
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
    required this.details,
  });

  final bool selected;
  final String title;
  final String description;
  final VoidCallback onTap;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? context.colors.accent : null,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.type.bodyStrong),
                      Text(description, style: context.type.small),
                      ...details,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
