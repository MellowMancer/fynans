import 'package:flutter/material.dart';

/// Tier 1: the raw palette, labelled by role.
abstract final class AppPalette {
  // --- The palette ---
  /// Seashell — the light theme's page tone, and light text on dark.
  static const Color background = Color(0xFFFFF5ED);

  /// Almond Silk — light borders and panels.
  static const Color background2 = Color(0xFFF1D4C8);

  /// Powder Blush — stronger light borders.
  static const Color background3 = Color(0xFFE3B3A2);

  /// Rosy Taupe.
  static const Color secondary = Color(0xFFBB8E81);

  /// Smoky Rose — the accent hue.
  static const Color accent = Color(0xFF936860);

  /// Gunmetal — the neutral dark.
  static const Color neutral = Color(0xFF3F403F);

  /// Charcoal Blue — the primary hue.
  static const Color primary = Color(0xFF1B4459);

  /// Sage Green — money in.
  static const Color positive = Color(0xFF78A776);

  /// Lobster Pink — money out.
  static const Color negative = Color(0xFFC05D5D);

  // --- Neutral ramp, deepened from Gunmetal ---
  static const Color neutral900 = Color(0xFF1B1C1B);
  static const Color neutral800 = Color(0xFF232423);
  static const Color neutral700 = Color(0xFF2C2D2C);
  static const Color neutral600 = Color(0xFF383938);
  static const Color neutral500 = Color(0xFF4C4D4C);
  static const Color neutral400 = Color(0xFF7C7D7C);
  static const Color neutral300 = Color(0xFF8E8F8E);
  static const Color neutral200 = Color(0xFFA9AAA9);
  static const Color neutral100 = Color(0xFFD8D9D8);

  /// Body and label inks for the light theme.
  static const Color neutralInk = Color(0xFF545654);
  static const Color neutralInkMuted = Color(0xFF6B6C6B);

  /// Warm inks for the dark theme, tinted toward Seashell.
  static const Color warmInk = Color(0xFFDCD5CF);
  static const Color warmInkMuted = Color(0xFFABA49E);
  static const Color warmInkFaint = Color(0xFF837C77);

  // --- Rose ramp ---
  static const Color accentDeep = Color(0xFF8B615A);
  static const Color accentDeeper = Color(0xFF7A544C);
  static const Color accentLight = Color(0xFFD2AFA3);
  static const Color accentTintLight = Color(0xFFFCECE7);
  static const Color accentTintDark = Color(0xFF3A2E2B);
  static const Color secondaryDeep = Color(0xFFA17A6D);
  static const Color secondaryTint = Color(0xFFDCC3B9);

  // --- Blue ramp ---
  static const Color primaryLight = Color(0xFF7FA0B0);
  static const Color primaryMid = Color(0xFF4A6B7C);
  static const Color primaryDusty = Color(0xFF6E93A6);
  static const Color primaryPale = Color(0xFF9DAFB8);
  static const Color primaryPaler = Color(0xFFB0C4CE);
  static const Color primarySky = Color(0xFF8FB0C2);
  static const Color primaryTintLight = Color(0xFFDAE5EB);
  static const Color primaryTintDark = Color(0xFF222E34);

  // --- Signal ramps ---
  /// Sage Green is a mid-tone: it needs deepening to read as text on Seashell.
  static const Color positiveDeep = Color(0xFF497345);
  static const Color positiveTintLight = Color(0xFFEAF2E9);
  static const Color positiveTintDark = Color(0xFF232B22);
  static const Color positiveBorderLight = Color(0xFFC6DEC4);
  static const Color positiveBorderDark = Color(0xFF3C5238);

  /// Lobster Pink needs deepening on light and lightening on dark.
  static const Color negativeDeep = Color(0xFFA34646);
  static const Color negativeLight = Color(0xFFD67B7B);
  static const Color negativeTintLight = Color(0xFFF9E4E3);
  static const Color negativeTintDark = Color(0xFF2E2020);
  static const Color negativeBorderLight = Color(0xFFEFC6C5);
  static const Color negativeBorderDark = Color(0xFF5A3434);

  // --- Surface tints ---
  static const Color surfaceMutedLight = Color(0xFFFBEDE5);
}
