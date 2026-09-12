import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/main_screen.dart';
import 'package:fynans/ui/screens/test_sms_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';

import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());
  tearDown(() => repository.dispose());

  Future<void> pumpMainScreen(WidgetTester tester, {required bool showSmsTab}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RepositoryProvider<TransactionRepository>.value(
          value: repository,
          child: MainScreen(showSmsTab: showSmsTab),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('iOS shell (showSmsTab: false) has only Expenses and Analytics',
      (tester) async {
    await pumpMainScreen(tester, showSmsTab: false);

    expect(find.text('EXPENSES'), findsOneWidget);
    expect(find.text('ANALYTICS'), findsOneWidget);
    expect(find.text('SMS (DEV)'), findsNothing);
    expect(find.byType(TestSmsScreen), findsNothing);
  });

  testWidgets('Android shell (showSmsTab: true) has all three tabs',
      (tester) async {
    // TestSmsScreen reads the SMS inbox in initState via permission_handler.
    // Stub the permission channel so the request resolves to denied instead
    // of hanging, which would otherwise time out pumpAndSettle.
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => switch (call.method) {
              'checkPermissionStatus' => 0, // PermissionStatus.denied
              'requestPermissions' => {13: 0}, // Permission.sms -> denied
              _ => null,
            });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    await pumpMainScreen(tester, showSmsTab: true);

    expect(find.text('EXPENSES'), findsOneWidget);
    expect(find.text('ANALYTICS'), findsOneWidget);
    expect(find.text('SMS (DEV)'), findsOneWidget);
  });
}
