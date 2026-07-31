import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_palette.dart';

/// Tier 2: semantic colour tokens, resolved per theme.
///
/// Every field names a *role*, never an appearance — `ink` is "the strongest
/// text colour", which is Gunmetal on light and Seashell on dark. That is why
/// there is no `onDark`: on a dark theme the text drawn on a filled accent is
/// itself dark, so the name would be a lie. It is [onAccent].
///
/// Widgets read these through `context.colors`, so switching theme is a change
/// of mapping rather than a change of every widget. Nothing here is `const` at
/// the point of use — that is the whole point.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceAccent,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkSecondary,
    required this.inkMuted,
    required this.inkFaint,
    required this.onAccent,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.primary,
    required this.primarySoft,
    required this.success,
    required this.successSoft,
    required this.successBorder,
    required this.danger,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.categorical,
  });

  /// Page background.
  final Color canvas;

  /// Card / raised surface.
  final Color surface;

  /// Inset rows and inactive segments.
  final Color surfaceMuted;

  /// Callout and eyebrow panels.
  final Color surfaceAccent;

  final Color border;
  final Color borderStrong;

  /// Headings — the strongest text colour.
  final Color ink;

  /// Body copy.
  final Color inkSecondary;

  /// Mono eyebrow labels and metadata.
  final Color inkMuted;

  /// Disabled / placeholder.
  final Color inkFaint;

  /// Text drawn on a filled accent or primary surface.
  final Color onAccent;

  final Color accent;
  final Color accentStrong;
  final Color accentSoft;

  final Color primary;
  final Color primarySoft;

  /// Money in.
  final Color success;
  final Color successSoft;
  final Color successBorder;

  /// Money out.
  final Color danger;
  final Color dangerSoft;
  final Color dangerBorder;

  /// Tag/category accents. Never contains the money hues — a chart colour that
  /// looked like a signal would read as one.
  final List<Color> categorical;

  static const AppColors light = AppColors(
    canvas: AppPalette.background,
    // Seashell, matching the canvas: cards are separated by their border, which
    // keeps pure white out of the UI entirely.
    surface: AppPalette.background,
    surfaceMuted: AppPalette.surfaceMutedLight,
    surfaceAccent: AppPalette.background2,
    border: AppPalette.background2,
    borderStrong: AppPalette.background3,
    ink: AppPalette.neutral,
    inkSecondary: AppPalette.neutralInk,
    inkMuted: AppPalette.neutralInkMuted,
    inkFaint: AppPalette.secondaryDeep,
    onAccent: AppPalette.background,
    accent: AppPalette.accentDeep,
    accentStrong: AppPalette.accentDeeper,
    accentSoft: AppPalette.accentTintLight,
    primary: AppPalette.primary,
    primarySoft: AppPalette.primaryTintLight,
    success: AppPalette.positiveDeep,
    successSoft: AppPalette.positiveTintLight,
    successBorder: AppPalette.positiveBorderLight,
    danger: AppPalette.negativeDeep,
    dangerSoft: AppPalette.negativeTintLight,
    dangerBorder: AppPalette.negativeBorderLight,
    categorical: <Color>[
      AppPalette.primary,
      AppPalette.accent,
      AppPalette.background3,
      AppPalette.neutral400,
      AppPalette.secondary,
      AppPalette.primaryMid,
      AppPalette.primaryPale,
      AppPalette.neutral,
      AppPalette.primaryDusty,
    ],
  );

  static const AppColors dark = AppColors(
    canvas: AppPalette.neutral900,
    surface: AppPalette.neutral800,
    surfaceMuted: AppPalette.neutral700,
    surfaceAccent: AppPalette.neutral,
    border: AppPalette.neutral600,
    borderStrong: AppPalette.neutral500,
    ink: AppPalette.background,
    inkSecondary: AppPalette.warmInk,
    inkMuted: AppPalette.warmInkMuted,
    inkFaint: AppPalette.warmInkFaint,
    onAccent: AppPalette.neutral900,
    accent: AppPalette.secondary,
    accentStrong: AppPalette.accentLight,
    accentSoft: AppPalette.accentTintDark,
    primary: AppPalette.primaryLight,
    primarySoft: AppPalette.primaryTintDark,
    success: AppPalette.positive,
    successSoft: AppPalette.positiveTintDark,
    successBorder: AppPalette.positiveBorderDark,
    danger: AppPalette.negativeLight,
    dangerSoft: AppPalette.negativeTintDark,
    dangerBorder: AppPalette.negativeBorderDark,
    categorical: <Color>[
      AppPalette.background3,
      AppPalette.neutral200,
      AppPalette.secondary,
      AppPalette.primaryDusty,
      AppPalette.neutral100,
      AppPalette.primarySky,
      AppPalette.secondaryTint,
      AppPalette.neutral300,
      AppPalette.primaryPaler,
    ],
  );

  /// Legible text colour for a filled swatch, using this theme's own inks. The
  /// categorical scale spans light and dark fills, so a single fixed label
  /// colour would fail at one end; a luminance threshold gets mid-tones wrong.
  Color inkOn(Color fill) =>
      _contrast(ink, fill) >= _contrast(canvas, fill) ? ink : canvas;

  /// WCAG contrast ratio between two opaque colours.
  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  @override
  AppColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceAccent,
    Color? border,
    Color? borderStrong,
    Color? ink,
    Color? inkSecondary,
    Color? inkMuted,
    Color? inkFaint,
    Color? onAccent,
    Color? accent,
    Color? accentStrong,
    Color? accentSoft,
    Color? primary,
    Color? primarySoft,
    Color? success,
    Color? successSoft,
    Color? successBorder,
    Color? danger,
    Color? dangerSoft,
    Color? dangerBorder,
    List<Color>? categorical,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceAccent: surfaceAccent ?? this.surfaceAccent,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      onAccent: onAccent ?? this.onAccent,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentSoft: accentSoft ?? this.accentSoft,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      successBorder: successBorder ?? this.successBorder,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      categorical: categorical ?? this.categorical,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      surfaceAccent: mix(surfaceAccent, other.surfaceAccent),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      ink: mix(ink, other.ink),
      inkSecondary: mix(inkSecondary, other.inkSecondary),
      inkMuted: mix(inkMuted, other.inkMuted),
      inkFaint: mix(inkFaint, other.inkFaint),
      onAccent: mix(onAccent, other.onAccent),
      accent: mix(accent, other.accent),
      accentStrong: mix(accentStrong, other.accentStrong),
      accentSoft: mix(accentSoft, other.accentSoft),
      primary: mix(primary, other.primary),
      primarySoft: mix(primarySoft, other.primarySoft),
      success: mix(success, other.success),
      successSoft: mix(successSoft, other.successSoft),
      successBorder: mix(successBorder, other.successBorder),
      danger: mix(danger, other.danger),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      dangerBorder: mix(dangerBorder, other.dangerBorder),
      categorical: [
        for (var i = 0; i < categorical.length; i++)
          mix(categorical[i], other.categorical[i]),
      ],
    );
  }
}

/// `context.colors.ink` — how widgets reach a colour.
extension AppColorsX on BuildContext {
  AppColors get colors {
    final colors = Theme.of(this).extension<AppColors>();
    assert(
      colors != null,
      'No AppColors in the theme. Build it with AppTheme.light()/dark(); a '
      'bare ThemeData does not carry the app tokens.',
    );
    return colors!;
  }
}
