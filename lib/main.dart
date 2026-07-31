import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fynans/entities/theme_preference.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ui/main_screen.dart';
import 'package:fynans/ports/settings_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/blocs/theme/theme_cubit.dart';
import 'package:fynans/adapters/data/hive_transaction_repository.dart';
import 'package:fynans/adapters/data/shared_prefs_settings_repository.dart';
import 'package:fynans/adapters/sms/sms_intake_service.dart';
import 'package:fynans/ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');

  // One-time upgrade path: drop auto-imported rows stamped with the old,
  // non-reproducible smsId scheme. Without this the sweep below cannot match
  // them and would import every message a second time.
  await HiveTransactionRepository().purgeLegacySmsRecords();

  // Read the appearance choice before the first frame — loading it after would
  // paint one frame in the wrong theme and flash.
  final settings = SharedPrefsSettingsRepository();
  final themePreference = await settings.readThemePreference();

  runApp(MyApp(settings: settings, themePreference: themePreference));
  // After the UI is up, sweep the inbox for bank-transaction SMS. De-dupe on
  // the raw-SMS id keeps this idempotent, so re-running on every launch never
  // creates duplicates; each imported record also keeps its original SMS text.
  SmsIntakeService.catchUp();
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settings,
    this.themePreference = ThemePreference.system,
  });

  final SettingsRepository settings;
  final ThemePreference themePreference;

  @override
  Widget build(BuildContext context) {
    // Composition root: build the one repository and expose it above the
    // Navigator so every route (including pushed screens) reads it via context.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TransactionRepository>(
          create: (_) => HiveTransactionRepository(),
        ),
        RepositoryProvider<SettingsRepository>.value(value: settings),
      ],
      // Above MaterialApp, so selecting a theme rebuilds the app itself.
      child: BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(settings, initial: themePreference),
        child: BlocBuilder<ThemeCubit, ThemePreference>(
          builder: (context, preference) => MaterialApp(
            title: 'Fynans',
            debugShowCheckedModeBanner: false,
            // en_IN gives the date pickers DD/MM/YYYY input and Indian digit
            // grouping, matching the ₹ formatting used throughout.
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en', 'IN'), Locale('en')],
            locale: const Locale('en', 'IN'),
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            // Both themes come from the same builder, so neither can drift;
            // AppColors.lerp animates the crossfade between them.
            themeMode: preference.themeMode,
            home: const MainScreen(),
          ),
        ),
      ),
    );
  }
}

/// Maps the entity onto Flutter's own enum. Lives here, at the framework edge,
/// so [ThemePreference] itself stays free of Flutter.
extension ThemePreferenceMode on ThemePreference {
  ThemeMode get themeMode => switch (this) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      };
}
