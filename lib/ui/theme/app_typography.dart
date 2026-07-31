import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';

/// Type tokens — metrics only.
abstract final class AppTypography {
  static const String sans = 'Iosevka';
  static const String mono = 'Iosevka';

  // --- Headings ---
  static const TextStyle display = TextStyle(
    fontFamily: sans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: sans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // --- Prose ---
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle small = TextStyle(
    fontFamily: sans,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Button text.
  static const TextStyle button = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0,
  );

  // --- Mono ---
  /// Uppercase eyebrow label — the signature of this theme.
  static const TextStyle label = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 1.1,
  );

  /// Metadata / code-ish values.
  static const TextStyle monoBody = TextStyle(
    fontFamily: mono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: mono,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// Money and other headline figures.
  static const TextStyle amount = TextStyle(
    fontFamily: mono,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle amountSmall = TextStyle(
    fontFamily: mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// Material text theme for [colors], so stock widgets inherit the right fonts
  /// *and* the right inks for the active theme.
  static TextTheme textThemeFor(AppColors colors) {
    final styles = AppTextStyles(colors);
    return TextTheme(
      displaySmall: styles.display,
      headlineMedium: styles.h1,
      headlineSmall: styles.h1,
      titleLarge: styles.h2,
      titleMedium: styles.h3,
      titleSmall: styles.bodyStrong,
      bodyLarge: styles.body,
      bodyMedium: styles.body,
      bodySmall: styles.small,
      labelLarge: styles.button,
      labelMedium: styles.label,
      labelSmall: styles.label,
    );
  }
}

/// The type scale with this theme's inks applied.
@immutable
class AppTextStyles {
  const AppTextStyles(this._colors);

  final AppColors _colors;

  TextStyle get display => AppTypography.display.copyWith(color: _colors.ink);
  TextStyle get h1 => AppTypography.h1.copyWith(color: _colors.ink);
  TextStyle get h2 => AppTypography.h2.copyWith(color: _colors.ink);
  TextStyle get h3 => AppTypography.h3.copyWith(color: _colors.ink);

  TextStyle get body => AppTypography.body.copyWith(color: _colors.inkSecondary);
  TextStyle get bodyStrong =>
      AppTypography.bodyStrong.copyWith(color: _colors.ink);
  TextStyle get small =>
      AppTypography.small.copyWith(color: _colors.inkSecondary);

  /// Left uncoloured: buttons set their own foreground per variant.
  TextStyle get button => AppTypography.button;

  TextStyle get label => AppTypography.label.copyWith(color: _colors.inkMuted);
  TextStyle get monoBody =>
      AppTypography.monoBody.copyWith(color: _colors.ink);
  TextStyle get monoSmall =>
      AppTypography.monoSmall.copyWith(color: _colors.inkMuted);
  TextStyle get amount => AppTypography.amount.copyWith(color: _colors.ink);
  TextStyle get amountSmall =>
      AppTypography.amountSmall.copyWith(color: _colors.ink);
}

/// `context.type.h2` — the type scale, resolved for the active theme.
extension AppTypographyX on BuildContext {
  AppTextStyles get type => AppTextStyles(colors);
}
