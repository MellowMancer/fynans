import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// Semantic tones for [AppPill]. Each maps to a fill/text/border triple so
/// callers never pick raw colours.
enum AppPillTone { neutral, muted, accent, success, danger, outline }

/// A compact rounded tag. One widget covers every chip in the design: plain
/// tags, mono codes, metadata chips with a leading icon, status colours, and
/// removable filter chips.
class AppPill extends StatelessWidget {
  const AppPill(
    this.label, {
    super.key,
    this.icon,
    this.tone = AppPillTone.neutral,
    this.mono = false,
    this.dense = false,
    this.onTap,
    this.onRemove,
    this.color,
  });

  final String label;

  /// Optional leading glyph.
  final IconData? icon;

  final AppPillTone tone;

  /// Render the label in JetBrains Mono (for codes and IDs).
  final bool mono;

  /// Tighter padding for inline use.
  final bool dense;

  final VoidCallback? onTap;

  /// When set, shows a trailing ✕ that calls this.
  final VoidCallback? onRemove;

  /// Overrides the tone's text/border colour — used for per-tag hues.
  final Color? color;

  _PillStyle get _style => switch (tone) {
        AppPillTone.neutral => const _PillStyle(
            AppColors.surfaceMuted, AppColors.ink, AppColors.border),
        AppPillTone.muted => const _PillStyle(
            AppColors.surfaceMuted, AppColors.inkMuted, AppColors.border),
        AppPillTone.accent => const _PillStyle(
            AppColors.accentSoft, AppColors.accentStrong, AppColors.accentSoft),
        AppPillTone.success => const _PillStyle(
            AppColors.successSoft, AppColors.success, AppColors.successBorder),
        AppPillTone.danger => const _PillStyle(
            AppColors.dangerSoft, AppColors.danger, AppColors.dangerBorder),
        AppPillTone.outline => const _PillStyle(
            AppColors.surface, AppColors.inkSecondary, AppColors.borderStrong),
      };

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final fg = color ?? style.foreground;
    final textStyle = mono
        ? AppTypography.monoSmall.copyWith(color: fg, letterSpacing: 0.6)
        : AppTypography.small.copyWith(color: fg, fontWeight: FontWeight.w500);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: dense ? 11 : 13, color: fg),
          AppSpacing.hGapXs,
        ],
        Flexible(
          child: Text(
            mono ? label.toUpperCase() : label,
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
