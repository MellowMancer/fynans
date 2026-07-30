import 'package:flutter/material.dart';

/// The app's colour tokens: a warm, editorial light palette.
///
/// Only these constants may hardcode colour values — every widget reads from
/// here (or from `Theme.of(context)`) so the palette has a single home.
abstract final class AppColors {
  // --- Surfaces (warm neutrals) ---
  /// Page background.
  static const Color canvas = Color(0xFFFAF9F7);

  /// Default card / raised surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle fill for inset rows and inactive segments.
  static const Color surfaceMuted = Color(0xFFF5F2EC);

  /// Warm beige fill used by callouts and "eyebrow" panels.
  static const Color surfaceAccent = Color(0xFFF0EAE0);

  // --- Borders ---
  static const Color border = Color(0xFFE6E1D7);
  static const Color borderStrong = Color(0xFFD8D2C6);

  // --- Ink (text) ---
  /// Headings — deep navy.
  static const Color ink = Color(0xFF14203F);

  /// Body copy.
  static const Color inkSecondary = Color(0xFF4A5468);

  /// Mono eyebrow labels and metadata — warm grey.
  static const Color inkMuted = Color(0xFF8B8578);

  /// Disabled / placeholder.
  static const Color inkFaint = Color(0xFFADA79A);

  static const Color onDark = Color(0xFFFFFFFF);

  // --- Accent (rust/brown) ---
  /// Eyebrow labels and accent rules.
  static const Color accent = Color(0xFF8A4B1C);

  /// Filled accent buttons.
  static const Color accentStrong = Color(0xFF6F3A12);

  /// Accent chip / callout fill.
  static const Color accentSoft = Color(0xFFF2E4D2);

  // --- Primary (blue) ---
  static const Color primary = Color(0xFF2563EB);
  static const Color primarySoft = Color(0xFFE8EFFD);

  // --- Semantic: money in / money out ---
  static const Color success = Color(0xFF2F6B4F);
  static const Color successSoft = Color(0xFFE7F1E9);
  static const Color successBorder = Color(0xFFCFE3D5);

  static const Color danger = Color(0xFFA93A2C);
  static const Color dangerSoft = Color(0xFFFBEAE7);
  static const Color dangerBorder = Color(0xFFF0D3CD);

  /// Muted, earthy hues for tag/category accents. Ordered so adjacent entries
  /// stay distinguishable when used as a categorical scale.
  static const List<Color> categorical = <Color>[
    Color(0xFF8A4B1C), // rust
    Color(0xFF2F6B4F), // pine
    Color(0xFF2F5B8A), // slate blue
    Color(0xFF7A4B7D), // plum
    Color(0xFFB07A2E), // ochre
    Color(0xFF3F7C7A), // teal
    Color(0xFFA0522D), // sienna
    Color(0xFF5B6478), // graphite
  ];
}
