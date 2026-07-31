import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/app_button.dart';

/// Placeholder for "nothing here yet" and error states, so every screen shows
/// the same shape instead of a bare centred `Text`.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.tone,
  });

  final String title;

  /// Optional supporting line.
  final String? message;

  final IconData? icon;

  /// Optional call to action (usually an [AppButton]).
  final Widget? action;

  /// Overrides the glyph colour — pass [context.colors.danger] for failures.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (tone ?? context.colors.accent).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: tone ?? context.colors.accent),
              ),
              AppSpacing.gapLg,
            ],
            Text(
              title,
              style: context.type.h3,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.gapXs,
              Text(
                message!,
                style: context.type.small,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[AppSpacing.gapLg, action!],
          ],
        ),
      ),
    );
  }
}

/// Centred progress indicator with the app's accent colour.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.accent,
        ),
      ),
    );
  }
}

/// The "couldn't load X, try again" state.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: title,
      message: message,
      tone: context.colors.danger,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
            ),
    );
  }
}

/// The two-button footer every editing sheet ends with (Cancel/Apply,
/// Clear/Done, …).
class AppSheetActions extends StatelessWidget {
  const AppSheetActions({
    super.key,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final String primaryLabel;

  /// Null disables the primary action (e.g.
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: secondaryLabel,
              variant: AppButtonVariant.secondary,
              onPressed: onSecondary,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: AppButton(
              label: primaryLabel,
              variant: AppButtonVariant.dark,
              onPressed: onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
