import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/widgets/common/common.dart';

enum _Mode { simple, advanced }

void main() {
  Future<List<_Mode>> pump(
    WidgetTester tester, {
    _Mode value = _Mode.simple,
    ThemeData? theme,
  }) async {
    final taps = <_Mode>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: AppSegmented<_Mode>(
              value: value,
              onChanged: taps.add,
              segments: const [
                AppSegment(
                  value: _Mode.simple,
                  label: 'Simple',
                  icon: Icons.view_agenda_outlined,
                ),
                AppSegment(value: _Mode.advanced, label: 'Advanced'),
              ],
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('tapping an unselected segment reports it', (tester) async {
    final taps = await pump(tester);

    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    expect(taps, [_Mode.advanced]);
  });

  testWidgets('tapping the selected segment reports nothing', (tester) async {
    final taps = await pump(tester);

    await tester.tap(find.text('Simple'));
    await tester.pumpAndSettle();

    // Re-selecting is not a change; firing here would churn state for nothing.
    expect(taps, isEmpty);
  });

  testWidgets('the selected fill follows the value', (tester) async {
    for (final (mode, label) in [
      (_Mode.simple, 'Simple'),
      (_Mode.advanced, 'Advanced'),
    ]) {
      await pump(tester, value: mode);
      await tester.pumpAndSettle();

      final filled = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList()
          .indexWhere((c) =>
              (c.decoration as BoxDecoration?)?.color ==
              AppColors.light.accentStrong);
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();

      expect(filled, isNot(-1));
      expect(labels[filled], label);
    }
  });

  testWidgets('keeps its colours in the dark theme', (tester) async {
    await pump(tester, theme: AppTheme.dark());
    await tester.pumpAndSettle();

    final fills = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.decoration as BoxDecoration?)?.color);
    expect(fills, contains(AppColors.dark.accentStrong));
  });

}
