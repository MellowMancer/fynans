import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/app_labels.dart';

/// A labelled field: mono uppercase label above its value, with an optional
/// leading glyph — the building block of every labelled field in the app.
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
            : Text(value!, style: context.type.bodyStrong));

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
  });

  final List<Widget> children;

  /// Two columns, dropping to one when each would be narrower than this.
  static const int _columns = 2;
  static const double _gap = AppSpacing.lg;
  static const double _minItemWidth = 150;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var cols = _columns;
        while (cols > 1 && (width - _gap * (cols - 1)) / cols < _minItemWidth) {
          cols--;
        }
        final itemWidth = (width - _gap * (cols - 1)) / cols;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final child in children)
              SizedBox(width: cols == 1 ? width : itemWidth, child: child),
          ],
        );
      },
    );
  }
}
