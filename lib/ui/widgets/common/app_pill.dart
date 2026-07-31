import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// Semantic tones for [AppPill].
enum AppPillTone { neutral, muted, accent, success, danger, outline }

/// A compact rounded tag.
class AppPill extends StatelessWidget {
  const AppPill(
    this.label, {
    super.key,
    this.icon,
    this.tone = AppPillTone.neutral,
    this.dense = false,
    this.onTap,
    this.onRemove,
    this.color,
  });

  final String label;

  /// Optional leading glyph.
  final IconData? icon;

  final AppPillTone tone;


  /// Tighter padding for inline use.
  final bool dense;

  final VoidCallback? onTap;

  /// When set, shows a trailing ✕ that calls this.
  final VoidCallback? onRemove;

  /// Overrides the tone's text/border colour — used for per-tag hues.
  final Color? color;

  /// Tone -> (fill, foreground, border) for the active theme.
  _PillStyle _styleFor(AppColors c) => switch (tone) {
        AppPillTone.neutral =>
          _PillStyle(c.surfaceMuted, c.ink, c.border),
        AppPillTone.muted =>
          _PillStyle(c.surfaceMuted, c.inkMuted, c.border),
        AppPillTone.accent =>
          _PillStyle(c.accentSoft, c.accentStrong, c.accentSoft),
        AppPillTone.success =>
          _PillStyle(c.successSoft, c.success, c.successBorder),
        AppPillTone.danger =>
          _PillStyle(c.dangerSoft, c.danger, c.dangerBorder),
        AppPillTone.outline =>
          _PillStyle(c.surface, c.inkSecondary, c.borderStrong),
      };

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(context.colors);
    final fg = color ?? style.foreground;
    final textStyle =
        context.type.small.copyWith(color: fg, fontWeight: FontWeight.w500);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: dense ? 11 : 13, color: fg),
          AppSpacing.hGapXs,
        ],
        Flexible(
          child: Text(
            label,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onRemove != null) ...[
          AppSpacing.hGapXs,
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: dense ? 11 : 13, color: fg),
          ),
        ],
      ],
    );

    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color == null
            ? style.background
            : color!.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillAll,
        border: Border.all(
          color: color == null ? style.border : color!.withValues(alpha: 0.25),
        ),
      ),
      child: content,
    );

    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillAll,
      child: pill,
    );
  }
}

class _PillStyle {
  const _PillStyle(this.background, this.foreground, this.border);

  final Color background;
  final Color foreground;
  final Color border;
}
