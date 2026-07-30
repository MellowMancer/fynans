import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/app_labels.dart';

/// A labelled field: mono uppercase label above its value, with an optional
/// leading glyph — the building block of every labelled field in the app.
///
/// Pass either [value] or [valueWidget].
class AppKeyValue extends StatelessWidget {
  const AppKeyValue({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
    this.mono = false,
    this.inline = false,
    this.onTap,
  }) : assert(
          value != null || valueWidget != null,
          'Provide either value or valueWidget',
        );

  final String label;
  final String? value;

  /// Use instead of [value] for richer content (pills, links, rows).
  final Widget? valueWidget;

  final IconData? icon;

  /// Render the value in JetBrains Mono (codes, IDs, amounts).
  final bool mono;

  /// Lay label and value on one line (label left, value right) instead of
  /// stacked.
  final bool inline;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = valueWidget ??
        (mono
            ? MonoText(value!)
            : Text(value!, style: AppTypography.bodyStrong));

    final labelWidget = AppSectionLabel(label, icon: icon);

    final content = inline
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: labelWidget),
              AppSpacing.hGapSm,
              Flexible(child: resolvedValue),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [labelWidget, AppSpacing.gapXs, resolvedValue],
          );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: content,
    );
  }
}

/// Lays [AppKeyValue]s (or any widgets) out in an evenly-spaced grid that
/// collapses to a single column on narrow screens.
class AppKeyValueGrid extends StatelessWidget {
  const AppKeyValueGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = AppSpacing.lg,
    this.runSpacing = AppSpacing.lg,
    this.minItemWidth = 150,
  });

  final List<Widget> children;

  /// Preferred column count; reduced automatically when space is tight.
  final int columns;

  final double spacing;
  final double runSpacing;

  /// Below this width per item, the grid drops a column.
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var cols = columns;
        while (cols > 1 && (width - spacing * (cols - 1)) / cols < minItemWidth) {
          cols--;
        }
        final itemWidth = (width - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: cols == 1 ? width : itemWidth, child: child),
          ],
        );
      },
    );
  }
}
