import 'package:flutter/material.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/tag_icon_widget.dart';

/// A single transaction row. Tapping expands the metadata, which is rendered
/// with the shared [AppKeyValue] so it matches every other labelled field in
/// the app.
class TransactionListItem extends StatefulWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    this.margin,
  });

  final Transaction transaction;
  final EdgeInsetsGeometry? margin;

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem> {
  bool _isExpanded = false;

  Transaction get _txn => widget.transaction;

  String get _title {
    if (_txn.party.trim().isNotEmpty) return _txn.party;
    if (_txn.tags.isNotEmpty) return Fmt.capitalizeAll(_txn.tags);
    return 'Untagged';
  }

  /// Secondary line: when the transaction happened, plus its tags.
  String get _meta {
    final parts = <String>[
      Fmt.dayMonthTime(_txn.date),
      if (_txn.tags.isNotEmpty) Fmt.capitalizeAll(_txn.tags),
    ];
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final tone = _txn.isCredit ? MoneyTone.positive : MoneyTone.negative;

    return AppCard(
      margin: widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.xs + 2,
          ),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TagIconWidget(tags: _txn.tags),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title,
                      style: AppTypography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapXxs,
                    // One ellipsized line rather than a Row of fixed-width
                    // pieces — the date+time string is long enough to overflow
                    // a Row on narrow screens.
                    MonoText.small(
                      _meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapSm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoneyText(
                    _txn.isCredit ? _txn.amount : -_txn.amount,
                    tone: tone,
                    style: AppTypography.amountSmall,
                    signed: _txn.isCredit,
                  ),
                  AppSpacing.gapXxs,
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: AppDuration.fast,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AnimatedSize(
            duration: AppDuration.normal,
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? _ExpandedDetails(transaction: _txn)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final note = transaction.note;
    final fields = <Widget>[
      AppKeyValue(
        label: 'Date',
        value: Fmt.fullDateTime(transaction.date),
        icon: Icons.event_outlined,
        mono: true,
      ),
      AppKeyValue(
        label: 'Direction',
        valueWidget: AppPill(
          transaction.isCredit ? 'Inflow' : 'Outflow',
          tone: transaction.isCredit ? AppPillTone.success : AppPillTone.danger,
          dense: true,
        ),
        icon: Icons.swap_vert_rounded,
      ),
      if (transaction.party.trim().isNotEmpty)
        AppKeyValue(
          // "Sender" for inflows, "Recipient" for outflows.
          label: Fmt.partyLabel(isCredit: transaction.isCredit),
          value: transaction.party,
          icon: transaction.isCredit
              ? Icons.call_received_rounded
              : Icons.person_outline,
        ),
      if (transaction.group.isNotEmpty)
        AppKeyValue(
          label: 'Group',
          valueWidget: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final g in transaction.group)
                AppPill(Fmt.capitalize(g), tone: AppPillTone.muted, dense: true),
            ],
          ),
          icon: Icons.folder_outlined,
        ),
      AppKeyValue(
        label: 'Source',
        valueWidget: AppPill(
          transaction.isAutoImported ? 'From SMS' : 'Added manually',
          icon: transaction.isAutoImported
              ? Icons.sms_outlined
              : Icons.edit_outlined,
          tone: AppPillTone.muted,
          dense: true,
        ),
        icon: Icons.input_rounded,
      ),
    ];

    final smsBody = transaction.smsBody;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          AppSpacing.gapMd,
          AppKeyValueGrid(children: fields),
          if (note != null && note.trim().isNotEmpty) ...[
            AppSpacing.gapMd,
            AppKeyValue(
              label: 'Note',
              value: note,
              icon: Icons.sticky_note_2_outlined,
            ),
          ],
          // Only auto-imported records carry the SMS they were parsed from.
          // Records imported before this field existed have a null body, so
          // the block is skipped rather than rendered empty.
          if (transaction.isAutoImported &&
              smsBody != null &&
              smsBody.trim().isNotEmpty) ...[
            AppSpacing.gapMd,
            AppQuoteBlock(
              smsBody,
              label: 'Original SMS',
              icon: Icons.subject_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
