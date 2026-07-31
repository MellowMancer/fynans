import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_palette.dart';

/// WCAG AA for normal-size text.
const double _kAaText = 4.5;

/// AA for large/bold text and for non-text indicators such as chart labels.
const double _kAaLarge = 3.0;

/// Distance below which two fills start reading as the same colour in a chart.
const double _kMinDeltaE = 18;

void main() {
  // Every rule is checked against both themes. A dark theme that skipped these
  // would be exactly as unreadable as a light one that did.
  const themes = {'light': AppColors.light, 'dark': AppColors.dark};

  themes.forEach((name, colors) {
    group('$name theme', () {
      final backgrounds = {
        'canvas': colors.canvas,
        'surface': colors.surface,
        'surfaceMuted': colors.surfaceMuted,
      };

      backgrounds.forEach((bgName, bg) {
        test('text tokens clear AA on $bgName', () {
          expect(contrast(colors.ink, bg), greaterThanOrEqualTo(7.0));
          expect(contrast(colors.inkSecondary, bg),
              greaterThanOrEqualTo(_kAaText));
          expect(contrast(colors.inkMuted, bg), greaterThanOrEqualTo(_kAaText));
          expect(contrast(colors.accent, bg), greaterThanOrEqualTo(_kAaText));
          expect(contrast(colors.success, bg), greaterThanOrEqualTo(_kAaText));
          expect(contrast(colors.danger, bg), greaterThanOrEqualTo(_kAaText));
          expect(contrast(colors.primary, bg), greaterThanOrEqualTo(_kAaText));
          // Placeholder text is exempt from AA, but must stay visible.
          expect(contrast(colors.inkFaint, bg), greaterThanOrEqualTo(_kAaLarge));
        });
      });

      test('soft fills stay legible under their own semantic ink', () {
        expect(contrast(colors.accent, colors.accentSoft),
            greaterThanOrEqualTo(_kAaText));
        expect(contrast(colors.success, colors.successSoft),
            greaterThanOrEqualTo(_kAaText));
        expect(contrast(colors.danger, colors.dangerSoft),
            greaterThanOrEqualTo(_kAaText));
        expect(contrast(colors.primary, colors.primarySoft),
            greaterThanOrEqualTo(_kAaText));
      });

      test('filled surfaces carry onAccent text', () {
        expect(contrast(colors.onAccent, colors.accentStrong),
            greaterThanOrEqualTo(_kAaText));
        expect(contrast(colors.onAccent, colors.primary),
            greaterThanOrEqualTo(_kAaText));
        // The FAB: ink fill, canvas glyph.
        expect(contrast(colors.canvas, colors.ink),
            greaterThanOrEqualTo(_kAaText));
      });

      test('inkOn picks a legible label for every categorical swatch', () {
        for (final fill in colors.categorical) {
          expect(contrast(colors.inkOn(fill), fill),
              greaterThanOrEqualTo(_kAaLarge),
              reason: 'no legible label ink for $fill');
        }
      });

      // Contrast is a luminance ratio, so it cannot see a hue difference: the
      // money colours sit at almost the same lightness on purpose. Telling them
      // apart is a perceptual-distance question, hence CIE76 ΔE.
      test('money in and money out are perceptually distant', () {
        expect(deltaE(colors.success, colors.danger), greaterThan(_kMinDeltaE));
      });

      // Sage Green and Lobster Pink mean credit/debit and success/failure. A
      // tag that merely looked like them would read as a signal in a chart, so
      // the chart scale must stay clear of both — not just avoid them exactly.
      test('no chart colour resembles the money colours', () {
        const reserved = {
          'sage green': AppPalette.positive,
          'lobster pink': AppPalette.negative,
        };
        for (final signal in {
          ...reserved,
          'success': colors.success,
          'danger': colors.danger,
        }.entries) {
          for (final fill in colors.categorical) {
            expect(deltaE(fill, signal.value), greaterThan(_kMinDeltaE),
                reason: 'chart colour $fill reads as ${signal.key}');
          }
        }
      });

      test('adjacent categorical swatches are distinguishable', () {
        final scale = colors.categorical;
        for (var i = 0; i < scale.length; i++) {
          final a = scale[i];
          final b = scale[(i + 1) % scale.length];
          expect(deltaE(a, b), greaterThan(_kMinDeltaE),
              reason: 'categorical $i and ${(i + 1) % scale.length} collide');
        }
      });

      test('no pure white or pure black', () {
        const white = Color(0xFFFFFFFF);
        const black = Color(0xFF000000);
        for (final c in [
          colors.canvas,
          colors.surface,
          colors.surfaceMuted,
          colors.ink,
        ]) {
          expect(c, isNot(white));
          expect(c, isNot(black));
        }
      });
    });
  });

  test('the two themes define the same tokens', () {
    // lerp walks both lists in step, so a length mismatch would throw during a
    // theme crossfade rather than at build time.
    expect(AppColors.light.categorical.length,
        AppColors.dark.categorical.length);
    expect(
      AppColors.light.lerp(AppColors.dark, 0.5),
      isA<AppColors>(),
      reason: 'themes must interpolate for an animated switch',
    );
  });
}

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// CIE76 colour difference in L*a*b*.
double deltaE(Color a, Color b) {
  final la = _lab(a);
  final lb = _lab(b);
  var sum = 0.0;
  for (var i = 0; i < 3; i++) {
    sum += (la[i] - lb[i]) * (la[i] - lb[i]);
  }
  return math.sqrt(sum);
}

List<double> _lab(Color c) {
  double toLinear(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  final r = toLinear(c.r);
  final g = toLinear(c.g);
  final b = toLinear(c.b);

  // sRGB -> XYZ (D65), normalised by the white point.
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;

  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;

  final fx = f(x);
  final fy = f(y);
  final fz = f(z);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}
