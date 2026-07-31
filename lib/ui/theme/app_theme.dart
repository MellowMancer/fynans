import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';

/// Builds the app's [ThemeData] so stock Material widgets pick up the palette
/// and the Iosevka type scale without per-widget overrides.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onAccent,
      primaryContainer: colors.primarySoft,
      onPrimaryContainer: colors.primary,
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      secondaryContainer: colors.accentSoft,
      onSecondaryContainer: colors.accentStrong,
      tertiary: colors.success,
      onTertiary: colors.onAccent,
      error: colors.danger,
      onError: colors.onAccent,
      errorContainer: colors.dangerSoft,
      onErrorContainer: colors.danger,
      surface: colors.surface,
      onSurface: colors.ink,
      surfaceContainerLowest: colors.surface,
      surfaceContainerLow: colors.canvas,
      surfaceContainer: colors.surfaceMuted,
      surfaceContainerHigh: colors.surfaceMuted,
      surfaceContainerHighest: colors.surfaceAccent,
      onSurfaceVariant: colors.inkSecondary,
      outline: colors.border,
      outlineVariant: colors.borderStrong,
    );

    final text = AppTypography.textThemeFor(colors);
    final styles = AppTextStyles(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // The tokens ride along on the ThemeData so `context.colors` can find
      // them, and so a theme switch animates through AppColors.lerp.
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      fontFamily: AppTypography.sans,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: styles.h1,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.inkMuted,
        titleTextStyle: styles.bodyStrong,
        subtitleTextStyle: styles.small,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: colors.inkMuted,
        collapsedIconColor: colors.inkMuted,
        textColor: colors.ink,
        collapsedTextColor: colors.ink,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: styles.body.copyWith(color: colors.inkFaint),
        labelStyle: styles.small,
        floatingLabelStyle: styles.small.copyWith(color: colors.accent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        // Primary, not ink: the active tab and the add button are the app's
        // interactive anchors, so they carry the primary hue.
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.inkMuted,
        selectedLabelStyle: styles.label,
        unselectedLabelStyle: styles.label,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: styles.h2,
        contentTextStyle: styles.body,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: colors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: styles.body.copyWith(color: colors.canvas),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: styles.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceMuted,
        circularTrackColor: colors.surfaceMuted,
      ),
      iconTheme: IconThemeData(color: colors.inkMuted, size: 18),
      splashColor: colors.accentSoft.withValues(alpha: 0.4),
      highlightColor: colors.surfaceMuted,
    );
  }
}
