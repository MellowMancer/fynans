import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/legacy_hive_cleanup.dart';

/// The cleanup deletes user files, so it is worth pinning exactly which.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('fynans_cleanup'));
  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name) =>
      File('${dir.path}/$name')..writeAsStringSync('stale');

  test('removes the old box and its lock', () async {
    final box = write('transactions.hive');
    final lock = write('transactions.lock');

    await deleteLegacyHiveBox(in_: dir);

    expect(box.existsSync(), isFalse);
    expect(lock.existsSync(), isFalse);
  });

  test('leaves the Drift database alone', () async {
    final db = write('fynans.db');
    write('transactions.hive');

    await deleteLegacyHiveBox(in_: dir);

    expect(db.existsSync(), isTrue,
        reason: 'deleting the live database would destroy the user\'s data');
  });

  test('is a no-op when there is nothing to clean up', () async {
    await deleteLegacyHiveBox(in_: dir);
    await deleteLegacyHiveBox(in_: dir);

    expect(dir.listSync(), isEmpty);
  });
}
