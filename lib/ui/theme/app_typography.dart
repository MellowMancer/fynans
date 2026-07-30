import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';

/// Type tokens. Two families, each with a job:
/// * **Inter** — headings and prose.
/// * **JetBrains Mono** — eyebrow labels, metadata and every number, so
///   amounts align in columns and read as data.
///
/// **Rule: mono is always UPPER-CASE.** Don't pair these mono styles with a
/// bare `Text`; use `MonoText` (or `AppSectionLabel` / `AppPill(mono: true)` /
/// `MoneyText`), which apply the casing for you.
abstract final class AppTypography {
  static const String sans = 'Inter';
  static const String mono = 'JetBrainsMono';

  // --- Headings (Inter) ---
  static const TextStyle display = TextStyle(
    fontFamily: sans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: sans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.ink,
  );

  // --- Prose (Inter) ---
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.inkSecondary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.ink,
  );

  static const TextStyle small = TextStyle(
    fontFamily: sans,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.inkSecondary,
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
    color: AppColors.inkMuted,
  );

  /// Metadata / code-ish values.
  static const TextStyle monoBody = TextStyle(
    fontFamily: mono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.ink,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: mono,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.inkMuted,
  );

  /// Money and other headline figures.
  static const TextStyle amount = TextStyle(
    fontFamily: mono,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );

  static const TextStyle amountSmall = TextStyle(
    fontFamily: mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.ink,
  );

  /// Full Material text theme, so stock widgets inherit the right fonts.
  static const TextTheme textTheme = TextTheme(
    displaySmall: display,
    headlineMedium: h1,
    headlineSmall: h1,
    titleLarge: h2,
    titleMedium: h3,
    titleSmall: bodyStrong,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: small,
    labelLarge: button,
    labelMedium: label,
    labelSmall: label,
  );
}
