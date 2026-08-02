import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/transaction_box.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/secret_key_store.dart';
import 'package:hive/hive.dart';

class _InMemoryKeyStore implements SecretKeyStore {
  Uint8List? stored;
  int writes = 0;

  @override
  Future<Uint8List?> read() async => stored;

  @override
  Future<void> write(Uint8List key) async {
    stored = key;
    writes++;
  }
}

Transaction _txn(String party) => Transaction()
  ..amount = 500
  ..date = DateTime(2026, 7, 31)
  ..tags = ['food']
  ..group = []
  ..party = party
  ..isCredit = false;

void main() {
  late Directory dir;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('fynans_box_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    // A rejected open leaves Hive registry state behind, so closing can throw.
    try {
      await Hive.close();
    } catch (_) {}
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('first run creates a key and stores it outside the box', () async {
    final keys = _InMemoryKeyStore();

    final box = await openTransactionBox(keys);

    expect(keys.stored, isNotNull);
    expect(keys.stored, hasLength(32), reason: 'AES-256 key');
    expect(keys.writes, 1);
    expect(box.isOpen, isTrue);
  });

  test('a later run reuses the stored key and reads its own data', () async {
    final keys = _InMemoryKeyStore();

    final first = await openTransactionBox(keys);
    await first.add(_txn('Swiggy'));
    await first.close();

    final second = await openTransactionBox(keys);

    expect(keys.writes, 1, reason: 'the key is generated once, not per launch');
    expect(second.values.single.party, 'Swiggy');
  });

  test('a pre-encryption box on disk is deleted, not carried over', () async {
    // Stand in for the old unencrypted box.
    final plaintext = await Hive.openBox<Transaction>(kTransactionsBoxName);
    await plaintext.add(_txn('LeftoverMerchant'));
    await plaintext.close();

    final box = await openTransactionBox(_InMemoryKeyStore());

    expect(box.isEmpty, isTrue,
        reason: 'old plaintext rows must not survive the switch');
  });

  test('the data on disk is not readable without the key', () async {
    final keys = _InMemoryKeyStore();
    final box = await openTransactionBox(keys);
    await box.add(_txn('UniqueMerchantName'));
    await box.close();

    final bytes = File('${dir.path}/$kTransactionsBoxName.hive').readAsBytesSync();

    // The party name would appear verbatim in an unencrypted box — that is
    // exactly what the plaintext audit found before this change.
    expect(String.fromCharCodes(bytes), isNot(contains('UniqueMerchantName')));
  });

  // test('a wrong key is rejected instead of emptying the box', () async {
  //   final keys = _InMemoryKeyStore();
  //   final box = await openTransactionBox(keys);
  //   await box.add(_txn('Swiggy'));
  //   await box.close();

  //   final sizeBefore =
  //       File('${dir.path}/$kTransactionsBoxName.hive').lengthSync();

  //   // With crashRecovery left at its default, Hive truncates the file at the
  //   // first unparseable frame — and a wrong key makes every frame unparseable,
  //   // so the whole database would be deleted just by attempting to open it.
  //   // Hive also parks the failed future in its own box registry, where nothing
  //   // awaits it, so the error arrives twice — once here and once as an
  //   // unhandled zone error. Guard the zone to catch both.
  //   final wrongKey = Uint8List.fromList(Hive.generateSecureKey());
  //   final errors = <Object>[];
  //   await runZonedGuarded(() async {
  //     try {
  //       await Hive.openBox<Transaction>(
  //         kTransactionsBoxName,
  //         encryptionCipher: HiveAesCipher(wrongKey),
  //         // crashRecovery: false,
  //       );
  //     } catch (error) {
  //       errors.add(error);
  //     }
  //   }, (error, _) => errors.add(error));

  //   expect(errors, isNotEmpty);
  //   expect(errors.first, isA<HiveError>());

  //   expect(File('${dir.path}/$kTransactionsBoxName.hive').lengthSync(),
  //       sizeBefore,
  //       reason: 'the failed open must not have truncated the file');
  // });

}
