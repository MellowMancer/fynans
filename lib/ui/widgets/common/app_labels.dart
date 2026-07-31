import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// Any text set in JetBrains Mono.
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.maxLines,
    this.overflow,
  }) : _small = false;

  /// Convenience for the smaller metadata size.
  const MonoText.small(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
  })  : style = null,
        _small = true;

  final String text;

  /// Defaults to `context.type.monoBody`, or the smaller size for
  /// [MonoText.small].
  final TextStyle? style;

  /// Set by [MonoText.small]; the style itself can only be resolved in build,
  /// because it carries a theme-dependent colour.
  final bool _small;

  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: (style ?? (_small ? context.type.monoSmall : context.type.monoBody))
          .copyWith(color: color),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Mono uppercase eyebrow label — the recurring motif of this theme Text is
/// upper-cased for you, so callers pass natural casing.
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

  /// Widget pinned after the text (e.g.
  final Widget? trailing;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = context.type.label.copyWith(color: color);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color ?? context.colors.inkMuted),
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

/// Flat page header — mono eyebrow over a title, an optional trailing action,
/// optional body, closed by a rule.
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.label,
    required this.title,
    this.trailing,
    this.child,
    this.showDivider = true,
  });

  final String label;
  final String title;

  /// Action pinned to the right of the title row.
  final Widget? trailing;

  /// Body rendered under the title row.
  final Widget? child;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSectionLabel(label),
                  AppSpacing.gapXxs,
                  Text(title, style: context.type.h2),
                ],
              ),
            ),
            if (trailing != null) ...[AppSpacing.hGapSm, trailing!],
          ],
        ),
        // Rule under the title row, separating it from the body.
        if (child != null) ...[
          AppSpacing.gapMd,
          const Divider(),
          AppSpacing.gapMd,
          // Flexible so a body containing its own Flexible still lays out when
          // the header sits in a fixed-height pager.
          Flexible(child: child!),
        ],
        if (showDivider) ...[AppSpacing.gapMd, const Divider()],
      ],
    );
  }
}
