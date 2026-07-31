import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:yaml/yaml.dart';

/// Iosevka's advance is half its em.
const double _kIosevkaAdvanceRatio = 0.5;

double _advance(String s, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width / s.length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final declared = (loadYaml(File('pubspec.yaml').readAsStringSync())
      as YamlMap)['flutter']['fonts'] as YamlList;

  test('every declared font family and asset is the bundled Iosevka', () {
    for (final family in declared) {
      expect(family['family'], AppTypography.sans);
      for (final face in family['fonts'] as YamlList) {
        expect(File(face['asset'] as String).existsSync(), isTrue,
            reason: '${face['asset']} is declared but missing');
      }
    }
    // Both type roles must name a family the pubspec actually ships, or Flutter
    // falls back without any build-time error.
    final families = {for (final f in declared) f['family'] as String};
    expect(families, contains(AppTypography.sans));
    expect(families, contains(AppTypography.mono));
  });

  testWidgets('the bundled faces parse and render monospaced', (tester) async {
    for (final face
        in (declared.first['fonts'] as YamlList).cast<YamlMap>()) {
      final asset = face['asset'] as String;
      final loader = FontLoader('IosevkaProbe')
        ..addFont(Future.value(
          File(asset).readAsBytesSync().buffer.asByteData(),
        ));
      await loader.load();

      const size = 40.0;
      final style = TextStyle(fontFamily: 'IosevkaProbe', fontSize: size);
      // '₹' is checked alongside the Latin range because the amount formatter
      // emits it on every screen.
      for (final sample in ['MMMM', 'iiii', '8888', '₹₹₹₹']) {
        expect(_advance(sample, style),
            closeTo(size * _kIosevkaAdvanceRatio, 0.5),
            reason: '$asset did not render "$sample" as Iosevka');
      }
    }
  });
}
