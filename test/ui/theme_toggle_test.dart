import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/theme/theme_cubit.dart';
import 'package:fynans/entities/theme_preference.dart';
import 'package:fynans/ports/settings_repository.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/widgets/app_drawer.dart';
import 'package:fynans/ui/widgets/common/common.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository([this.stored = ThemePreference.system]);

  ThemePreference stored;
  int writes = 0;

  @override
  Future<ThemePreference> readThemePreference() async => stored;

  @override
  Future<void> writeThemePreference(ThemePreference preference) async {
    stored = preference;
    writes++;
  }
}

void main() {
  group('ThemePreference storage round-trip', () {
    test('every value survives a write/read cycle', () {
      for (final preference in ThemePreference.values) {
        expect(
          ThemePreference.fromStorage(preference.storageValue),
          preference,
        );
      }
    });

    test('unknown and missing values fall back to system', () {
      // A value written by a future version must not crash the app.
      expect(ThemePreference.fromStorage(null), ThemePreference.system);
      expect(ThemePreference.fromStorage('sepia'), ThemePreference.system);
    });
  });

  group('ThemeCubit', () {
    test('starts from the value loaded before the first frame', () {
      final cubit = ThemeCubit(
        _FakeSettingsRepository(ThemePreference.dark),
        initial: ThemePreference.dark,
      );
      expect(cubit.state, ThemePreference.dark);
    });

    test('selecting persists the choice', () async {
      final settings = _FakeSettingsRepository();
      final cubit = ThemeCubit(settings);

      await cubit.select(ThemePreference.dark);

      expect(cubit.state, ThemePreference.dark);
      expect(settings.stored, ThemePreference.dark);
    });

    test('re-selecting the current value writes nothing', () async {
      final settings = _FakeSettingsRepository();
      final cubit = ThemeCubit(settings, initial: ThemePreference.light);

      await cubit.select(ThemePreference.light);

      expect(settings.writes, 0);
    });
  });

  group('the drawer toggle', () {
    Future<ThemeCubit> pumpDrawer(
      WidgetTester tester, {
      ThemePreference initial = ThemePreference.system,
      SettingsRepository? settings,
    }) async {
      final cubit = ThemeCubit(
        settings ?? _FakeSettingsRepository(),
        initial: initial,
      );
      await tester.pumpWidget(
        BlocProvider<ThemeCubit>.value(
          value: cubit,
          // themeMode is wired exactly as main.dart wires it, so selecting a
          // mode rebuilds the app the same way it does on device. Without this
          // the test never exercises a theme change at all.
          child: BlocBuilder<ThemeCubit, ThemePreference>(
            builder: (context, preference) => MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: switch (preference) {
                ThemePreference.system => ThemeMode.system,
                ThemePreference.light => ThemeMode.light,
                ThemePreference.dark => ThemeMode.dark,
              },
              home: const Scaffold(drawer: AppDrawer(), body: SizedBox()),
            ),
          ),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('offers auto, light and dark', (tester) async {
      await pumpDrawer(tester);

      expect(find.text('APPEARANCE'), findsOneWidget);
      // Pills are sentence-case; only mono text is upper-cased.
      for (final label in ['Auto', 'Light', 'Dark']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('tapping a mode selects and persists it', (tester) async {
      final settings = _FakeSettingsRepository();
      final cubit = await pumpDrawer(tester, settings: settings);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(cubit.state, ThemePreference.dark);
      expect(settings.stored, ThemePreference.dark);
    });

    testWidgets('the theme actually changes when a mode is picked',
        (tester) async {
      await pumpDrawer(tester);
      expect(Theme.of(tester.element(find.byType(AppDrawer))).brightness,
          Brightness.light);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
        reason: 'picking Dark must override the platform brightness',
      );
    });

    testWidgets('exactly the selected mode is highlighted', (tester) async {
      await pumpDrawer(tester, initial: ThemePreference.dark);

      // Asserting "some pill is accent-toned" would pass for any selection, so
      // check which one: exactly one, and it is Dark.
      final accented = tester
          .widgetList<AppPill>(find.byType(AppPill))
          .where((pill) => pill.tone == AppPillTone.accent)
          .map((pill) => pill.label)
          .toList();
      expect(accented, ['Dark']);
    });

    testWidgets('the highlight follows the selection', (tester) async {
      await pumpDrawer(tester, initial: ThemePreference.system);

      String accentedLabel() => tester
          .widgetList<AppPill>(find.byType(AppPill))
          .firstWhere((pill) => pill.tone == AppPillTone.accent)
          .label;

      expect(accentedLabel(), 'Auto');

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(accentedLabel(), 'Light');
    });
  });
}
