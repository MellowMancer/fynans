import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// Any text set in JetBrains Mono. **Mono is always upper-case in this theme**,
/// so this widget applies the casing itself — render mono through here (or
/// through [AppSectionLabel] / `AppPill(mono: true)` / `MoneyText`) rather than
/// a bare `Text` with a mono style, and the rule can't be forgotten.
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.maxLines,
    this.overflow,
  });

  /// Convenience for the smaller metadata size.
  const MonoText.small(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
  }) : style = AppTypography.monoSmall;

  final String text;

  /// Defaults to [AppTypography.monoBody].
  final TextStyle? style;

  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: (style ?? AppTypography.monoBody).copyWith(color: color),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Mono uppercase eyebrow label — the recurring motif of this theme
///
/// Text is upper-cased for you, so callers pass natural casing.
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(
    this.text, {
    super.key,
    this.color,
    this.icon,
    this.trailing,
    this.padding,
  });

  final String text;
  final Color? color;

  /// Small leading glyph, sized to the label.
  final IconData? icon;

  /// Widget pinned after the text (e.g. a count).
  final Widget? trailing;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.label.copyWith(color: color);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color ?? AppColors.inkMuted),
          AppSpacing.hGapXs,
        ],
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[AppSpacing.hGapSm, trailing!],
      ],
    );

    return padding == null ? row : Padding(padding: padding!, child: row);
  }
}
