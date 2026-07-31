import 'package:flutter/material.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ui/utils/formatters.dart';

/// One active criterion, rendered as a removable chip.
@immutable
class FilterChipSpec {
  const FilterChipSpec({
    required this.label,
    required this.icon,
    required this.clear,
  });

  final String label;
  final IconData icon;

  /// Returns the filter with just this criterion removed.
  final TransactionFilter Function(TransactionFilter) clear;
}

/// Describes every active criterion in [filter] as a chip.
List<FilterChipSpec> describeFilter(TransactionFilter filter) {
  final chips = <FilterChipSpec>[];

  // One chip per selected value, so each can be removed independently.
  for (final group in filter.groups) {
    chips.add(FilterChipSpec(
      label: 'Group: ${Fmt.capitalize(group)}',
      icon: Icons.folder_outlined,
      clear: (f) => f.copyWith(groups: {...f.groups}..remove(group)),
    ));
  }
  for (final tag in filter.tags) {
    chips.add(FilterChipSpec(
      label: 'Tag: ${Fmt.capitalize(tag)}',
      icon: Icons.label_outline,
      clear: (f) => f.copyWith(tags: {...f.tags}..remove(tag)),
    ));
  }
  for (final party in filter.parties) {
    chips.add(FilterChipSpec(
      label: 'Party: ${Fmt.capitalize(party)}',
      icon: Icons.person_outline,
      clear: (f) => f.copyWith(parties: {...f.parties}..remove(party)),
    ));
  }
  if (!filter.direction.isAny) {
    chips.add(FilterChipSpec(
      label: filter.direction.label,
      icon: filter.direction == DirectionFilter.inflow
          ? Icons.south_west_rounded
          : Icons.north_east_rounded,
      clear: (f) => f.copyWith(direction: DirectionFilter.any),
    ));
  }
  if (filter.minAmount != null || filter.maxAmount != null) {
    chips.add(FilterChipSpec(
      label: _amountLabel(filter),
      icon: Icons.straighten_rounded,
      clear: (f) => f.copyWith(minAmount: null, maxAmount: null),
    ));
  }

  return chips;
}

String _amountLabel(TransactionFilter filter) {
  final min = filter.minAmount;
  final max = filter.maxAmount;
  if (min != null && max != null) {
    return '${Fmt.money(min, decimals: 0)} – ${Fmt.money(max, decimals: 0)}';
  }
  if (min != null) return '≥ ${Fmt.money(min, decimals: 0)}';
  return '≤ ${Fmt.money(max!, decimals: 0)}';
}
