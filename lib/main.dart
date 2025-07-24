import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fynans/main_screen.dart';
import 'package:fynans/services/isar_service.dart';

// Global instance of the Isar service for easy access from other files.
final isarService = IsarService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMPORARY: This will wipe all data from your database.
  // It's useful for applying breaking schema changes during development.
  // Run the app ONCE with this line, then REMOVE or COMMENT IT OUT.
  // await isarService.clearDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fynans',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
