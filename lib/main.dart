import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ui/main_screen.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/data/hive_transaction_repository.dart';
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

  runApp(const MyApp());
  // After the UI is up, sweep the inbox for bank-transaction SMS. De-dupe on
  // the raw-SMS id keeps this idempotent, so re-running on every launch never
  // creates duplicates; each imported record also keeps its original SMS text.
  SmsIntakeService.catchUp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Composition root: build the one repository and expose it above the
    // Navigator so every route (including pushed screens) reads it via context.
    return RepositoryProvider<TransactionRepository>(
      create: (_) => HiveTransactionRepository(),
      child: MaterialApp(
        title: 'Fynans',
        debugShowCheckedModeBanner: false,
        // en_IN gives the date pickers DD/MM/YYYY input and Indian digit
        // grouping, matching the ₹ formatting used throughout.
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en', 'IN'), Locale('en')],
        locale: const Locale('en', 'IN'),
        theme: AppTheme.light(),
        home: const MainScreen(),
      ),
    );
  }
}
