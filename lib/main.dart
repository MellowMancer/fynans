import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/theme_preference.dart';
import 'package:fynans/ui/main_screen.dart';
import 'package:fynans/ports/settings_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/blocs/theme/theme_cubit.dart';
import 'package:fynans/adapters/data/drift_transaction_repository.dart';
import 'package:fynans/adapters/data/encrypted_database.dart';
import 'package:fynans/adapters/data/keystore_secret_key_store.dart';
import 'package:fynans/adapters/data/shared_prefs_settings_repository.dart';
import 'package:fynans/adapters/sms/sms_intake_service.dart';
import 'package:fynans/ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One database and one repository, passed everywhere. A second connection to
  // the same file would not see the first one's writes, so live queries would
  // silently stop updating.
  final database = await openEncryptedDatabase(const KeystoreSecretKeyStore());
  final TransactionRepository repository = DriftTransactionRepository(database);
  final settings = SharedPrefsSettingsRepository();
  // Different stores, so these overlap rather than sum. The purge is a one-time
  // upgrade path dropping rows stamped with the old, non-reproducible smsId
  // scheme; the appearance choice must be read before the first frame, or it
  // paints once in the wrong theme.
  final (_, themePreference) = await (
    repository.purgeLegacySmsRecords(),
    settings.readThemePreference(),
  ).wait;

  runApp(MyApp(
    repository: repository,
    settings: settings,
    themePreference: themePreference,
  ));
  // After the UI is up, sweep the inbox for bank-transaction SMS.
  SmsIntakeService.catchUp(repository);
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.repository,
    required this.settings,
    this.themePreference = ThemePreference.system,
  });

  final TransactionRepository repository;
  final SettingsRepository settings;
  final ThemePreference themePreference;

  @override
  Widget build(BuildContext context) {
    // Composition root: build the one repository and expose it above the
    // Navigator so every route (including pushed screens) reads it via context.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TransactionRepository>.value(value: repository),
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

/// Maps the entity onto Flutter's own enum.
extension ThemePreferenceMode on ThemePreference {
  ThemeMode get themeMode => switch (this) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      };
}
