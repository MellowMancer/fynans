import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// Button styles from the design: blue call-to-action, dark navy, rust accent,
/// bordered white, and borderless.
enum AppButtonVariant { primary, dark, accent, secondary, ghost }

enum AppButtonSize { sm, md }

/// The single button widget. Variants + optional icon/expand/loading props
/// replace what would otherwise be several bespoke button widgets.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Leading glyph.
  final IconData? icon;

  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Stretch to the available width.
  final bool expand;

  /// Swaps the leading glyph for a spinner and blocks taps.
  final bool loading;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final isDense = size == AppButtonSize.sm;
    final fg = _enabled ? spec.foreground : AppColors.inkFaint;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: isDense ? 12 : 14,
            height: isDense ? 12 : 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: isDense ? 14 : 16, color: fg),
        if (loading || icon != null) AppSpacing.hGapSm,
        Text(
          label,
          style: (isDense ? AppTypography.small : AppTypography.button).copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final button = Material(
      color: _enabled ? spec.background : AppColors.surfaceMuted,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: _enabled ? onPressed : null,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDense ? AppSpacing.md : AppSpacing.lg,
            vertical: isDense ? AppSpacing.sm - 1 : AppSpacing.md - 1,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: spec.border == null
                ? null
                : Border.all(
                    color: _enabled ? spec.border! : AppColors.border,
                  ),
          ),
          child: child,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  _ButtonSpec get _spec => switch (variant) {
        AppButtonVariant.primary =>
          const _ButtonSpec(AppColors.primary, AppColors.onDark),
        AppButtonVariant.dark =>
          const _ButtonSpec(AppColors.ink, AppColors.onDark),
        AppButtonVariant.accent =>
          const _ButtonSpec(AppColors.accentStrong, AppColors.onDark),
        AppButtonVariant.secondary => const _ButtonSpec(
            AppColors.surface, AppColors.ink, AppColors.borderStrong),
        AppButtonVariant.ghost =>
          const _ButtonSpec(Colors.transparent, AppColors.accent),
      };
}

class _ButtonSpec {
  const _ButtonSpec(this.background, this.foreground, [this.border]);

  final Color background;
  final Color foreground;
  final Color? border;
}
