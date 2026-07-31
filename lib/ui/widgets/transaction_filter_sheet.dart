import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// The choices a [TransactionFilterSheet] needs to populate its pickers.
class FilterOptions {
  const FilterOptions({
    required this.groups,
    required this.tags,
    required this.parties,
  });

  final List<String> groups;
  final List<String> tags;
  final List<String> parties;
}

/// One sheet covering every filter criterion: group, tag, party, direction and
/// amount bounds.
class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({
    super.key,
    required this.initialFilter,
    required this.options,
  });

  final TransactionFilter initialFilter;
  final FilterOptions options;

  static Future<TransactionFilter?> show({
    required BuildContext context,
    required TransactionFilter filter,
    required FilterOptions options,
  }) {
    return showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      constraints: const BoxConstraints(maxHeight: 640),
      builder: (_) => TransactionFilterSheet(
        initialFilter: filter,
        options: options,
      ),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _draft = widget.initialFilter;
  late final TextEditingController _min = TextEditingController(
    text: widget.initialFilter.minAmount?.toStringAsFixed(0) ?? '',
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.initialFilter.maxAmount?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  /// Folds the typed bounds into the draft; blank means "no bound".
  TransactionFilter get _resolved => _draft.copyWith(
        minAmount: double.tryParse(_min.text.trim()),
        maxAmount: double.tryParse(_max.text.trim()),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Text('Filters', style: context.type.h2),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              children: [
                const AppSectionLabel('Direction'),
                AppSpacing.gapSm,
                Row(
                  children: [
                    for (final direction in DirectionFilter.values) ...[
                      AppPill(
                        direction.label,
                        tone: _draft.direction == direction
                            ? AppPillTone.accent
                            : AppPillTone.outline,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(direction: direction),
                        ),
                      ),
                      AppSpacing.hGapSm,
                    ],
                  ],
                ),
                AppSpacing.gapLg,
                const AppSectionLabel('Amount range'),
                AppSpacing.gapSm,
                Row(
                  children: [
                    Expanded(child: _AmountField(controller: _min, hint: 'Min')),
                    AppSpacing.hGapSm,
                    Expanded(child: _AmountField(controller: _max, hint: 'Max')),
                  ],
                ),
                AppSpacing.gapLg,
                AppMultiSelectField(
                  label: 'Group',
                  options: widget.options.groups,
                  selected: _draft.groups,
                  formatOption: Fmt.capitalize,
                  onChanged: (values) =>
                      setState(() => _draft = _draft.copyWith(groups: values)),
                ),
                AppMultiSelectField(
                  label: 'Tag',
                  options: widget.options.tags,
                  selected: _draft.tags,
                  formatOption: Fmt.capitalize,
                  onChanged: (values) =>
                      setState(() => _draft = _draft.copyWith(tags: values)),
                ),
                AppMultiSelectField(
                  label: 'Party',
                  options: widget.options.parties,
                  selected: _draft.parties,
                  formatOption: Fmt.capitalize,
                  onChanged: (values) =>
                      setState(() => _draft = _draft.copyWith(parties: values)),
                ),
              ],
            ),
          ),
          const Divider(),
          AppSheetActions(
            secondaryLabel: 'Clear all',
            onSecondary: () =>
                Navigator.pop(context, const TransactionFilter.empty()),
            primaryLabel: 'Apply',
            onPrimary: () => Navigator.pop(context, _resolved),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: context.type.monoBody,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        prefixText: '${Fmt.currencySymbol} ',
        prefixStyle: context.type.monoBody,
      ),
    );
  }
}

