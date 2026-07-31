import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';

/// A compact bordered icon button, matching [AppButton]'s secondary look for
/// places where a label would crowd the row.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Renders in the accent treatment, for toggles that are currently active.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = !enabled
        ? context.colors.inkFaint
        : selected
            ? context.colors.accentStrong
            : context.colors.ink;

    final button = Material(
      color: selected ? context.colors.accentSoft : context.colors.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 1),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected ? context.colors.accent : context.colors.borderStrong,
            ),
          ),
          child: Icon(icon, size: 18, color: foreground),
        ),
      ),
    );

    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}
