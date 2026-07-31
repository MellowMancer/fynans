import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/adapters/blocs/theme/theme_cubit.dart';
import 'package:fynans/entities/theme_preference.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/common.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSectionLabel('Menu', color: context.colors.accent),
                  AppSpacing.gapXs,
                  Text('Fynans', style: context.type.display),
                ],
              ),
            ),
            const Divider(),
            const _AppearanceToggle(),
            const Divider(),
            _DrawerItem(
              icon: Icons.tune,
              label: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.info_outline,
              label: 'About',
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: MonoText.small('Device-local · no cloud sync'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light / dark / follow-the-device, persisted through [ThemeCubit].
class _AppearanceToggle extends StatelessWidget {
  const _AppearanceToggle();

  static const List<(ThemePreference, String, IconData)> _options = [
    (ThemePreference.system, 'Auto', Icons.brightness_auto_outlined),
    (ThemePreference.light, 'Light', Icons.light_mode_outlined),
    (ThemePreference.dark, 'Dark', Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ThemeCubit>().state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSectionLabel('Appearance'),
          AppSpacing.gapSm,
          // Wrap, not Row: three pills can exceed a narrow drawer.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (preference, label, icon) in _options)
                AppPill(
                  label,
                  icon: icon,
                  tone: preference == selected
                      ? AppPillTone.accent
                      : AppPillTone.outline,
                  onTap: () => context.read<ThemeCubit>().select(preference),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: context.colors.inkMuted),
      title: Text(label, style: context.type.bodyStrong),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxs,
      ),
    );
  }
}
