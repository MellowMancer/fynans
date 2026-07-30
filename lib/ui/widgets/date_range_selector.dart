import 'package:flutter/material.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/ui/widgets/date_range_calendar.dart';
import 'package:fynans/use_cases/date_range_presets.dart';

/// Earliest date the custom picker allows.
const int _kPickerHistoryYears = 5;

/// Quick-span chips for the advanced view. Selecting a preset resolves it to a
/// concrete [DateRange]; "Custom Range" opens a date-range picker instead.
///
/// Built from [AppPill] so it needs no bespoke chip widget.
class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.currentRange,
    this.label = 'Showing',
    this.now,
  });

  /// The currently active preset, highlighted in the row.
  final DateRangePreset selected;

  /// Called with the resolved span and the preset that produced it.
  final void Function(DateRange range, DateRangePreset preset) onChanged;

  /// Seeds the custom calendar with what is already selected.
  final DateRange? currentRange;

  final String label;

  /// Injectable clock, so preset resolution is testable.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionLabel(label),
        AppSpacing.gapSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in DateRangePreset.values)
              AppPill(
                preset.label,
                icon: preset.isCustom ? Icons.date_range_outlined : null,
                tone: preset == selected
                    ? AppPillTone.accent
                    : AppPillTone.outline,
                onTap: () => _select(context, preset),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _select(BuildContext context, DateRangePreset preset) async {
    if (!preset.isCustom) {
      onChanged(
        resolveDateRangePreset(preset, now: now ?? DateTime.now()),
        preset,
      );
      return;
    }

    final today = now ?? DateTime.now();
    final picked = await DateRangeCalendarSheet.show(
      context: context,
      firstDate: DateTime(today.year - _kPickerHistoryYears),
      lastDate: today,
      initialRange: currentRange,
    );

    if (picked == null) return;
    onChanged(picked, DateRangePreset.custom);
  }
}


/// Opens the quick-span chips in a sheet, so the header only needs a single
/// calendar button instead of a chip row.
Future<void> showDateRangeSheet({
  required BuildContext context,
  required DateRangePreset selected,
  required DateRange currentRange,
  required void Function(DateRange range, DateRangePreset preset) onChanged,
  DateTime? now,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: DateRangeSelector(
          label: 'Date range',
          selected: selected,
          currentRange: currentRange,
          now: now,
          onChanged: (range, preset) {
            Navigator.pop(sheetContext);
            onChanged(range, preset);
          },
        ),
      ),
    ),
  );
}
