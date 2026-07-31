import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// One choice in an [AppSegmented].
@immutable
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;

  /// Optional leading glyph.
  final IconData? icon;
}

/// A grouped set of mutually exclusive choices, drawn as one track with the
/// selected option raised inside it.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;


  /// Gap between the track's edge and the raised segment.
  static const double _trackInset = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_trackInset),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final segment in segments) _buildSegment(context, segment),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(BuildContext context, AppSegment<T> segment) {
    final colors = context.colors;
    final selected = segment.value == value;
    // Filled, not the chips' tint: on this track the tint sat ΔE 1.7 from the
    // background, so the selection was invisible.
    final foreground = selected ? colors.onAccent : colors.inkSecondary;

    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? colors.accentStrong : Colors.transparent,
          borderRadius: AppRadius.pillAll,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: selected ? null : () => onChanged(segment.value),
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (segment.icon != null) ...[
                    Icon(segment.icon, size: 13, color: foreground),
                    AppSpacing.hGapXs,
                  ],
                  Text(
                    segment.label,
                    style: context.type.small.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
