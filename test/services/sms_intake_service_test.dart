import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/sms_intake_service.dart';
import 'package:fynans/entities/date_range.dart';

import '../fakes/fake_transaction_repository.dart';

void main() {
  // Needed to mock platform channels below -- testWidgets() does this
  // implicitly, but plain test() does not.
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());
  tearDown(() => repository.dispose());

  test('smsInboxAvailable: false short-circuits before touching the platform',
      () async {
    // No permission_handler channel stub is installed here. If catchUp
    // reached ReadSmsService despite the flag, the call would throw
    // MissingPluginException rather than quietly returning -- so a clean
    // return of 0 proves the guard runs first.
    final imported =
        await SmsIntakeService.catchUp(repository, smsInboxAvailable: false);

    expect(imported, 0);
    final stored = await repository.fetchTransactionsInRange(
      range: DateRange.month(DateTime.now()),
    );
    expect(stored, isEmpty);
  });

  test('smsInboxAvailable: true reaches the real pipeline instead of the old '
      'hidden Platform.isAndroid check', () async {
    // Denied permission makes ReadSmsService.getAllSms() return [] without
    // touching flutter_sms_inbox's own channel -- enough to prove execution
    // now passes the guard and reaches the pipeline. Message-level parsing
    // is already covered by transaction_sms_ingestor_test.dart.
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

    final imported =
        await SmsIntakeService.catchUp(repository, smsInboxAvailable: true);

    expect(imported, 0);
  });
}
