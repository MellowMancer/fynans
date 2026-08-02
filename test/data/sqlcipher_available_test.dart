import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yaml/yaml.dart';

/// Guards the one thing that fails silently.
///
/// Stock SQLite accepts every statement and ignores `PRAGMA key` without
/// complaint, so a build that linked the wrong library still works perfectly —
/// it just writes the database in plaintext. Nothing surfaces that at runtime
/// except an explicit check.
void main() {
  test('the linked SQLite build is SQLCipher', () {
    final db = sqlite3.openInMemory();

    // On stock SQLite this returns ZERO ROWS rather than throwing, because
    // unknown pragmas are silently ignored. Emptiness is the signal.
    final version = db.select('PRAGMA cipher_version;');

    expect(
      version,
      isNotEmpty,
      reason: 'SQLCipher is not linked — databases would be plaintext',
    );
    db.close();
  });

  test('a keyed database rejects the wrong key', () {
    final file = File(
      '${Directory.systemTemp.createTempSync('fynans_cipher').path}/t.db',
    );
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = sqlite3.open(file.path)
      ..execute('PRAGMA key = "x\'${'a' * 64}\'";');
    db.execute('CREATE TABLE t (v TEXT);');
    db.execute("INSERT INTO t VALUES ('UniqueMerchantName');");
    db.close();

    // A different key must fail to read, and must not damage the file.
    final sizeBefore = file.lengthSync();
    expect(
      () {
        final wrong = sqlite3.open(file.path)
          ..execute('PRAGMA key = "x\'${'b' * 64}\'";');
        wrong.select('SELECT * FROM t;');
      },
      throwsA(isA<SqliteException>()),
      reason: 'SQLCipher returns SQLITE_NOTADB rather than recovering',
    );
    expect(file.lengthSync(), sizeBefore);
  });

  test('the encrypted file holds no readable plaintext', () {
    final file = File(
      '${Directory.systemTemp.createTempSync('fynans_cipher2').path}/t.db',
    );
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = sqlite3.open(file.path)
      ..execute('PRAGMA key = "x\'${'c' * 64}\'";');
    db.execute('CREATE TABLE t (v TEXT);');
    db.execute("INSERT INTO t VALUES ('UniqueMerchantName');");
    db.close();

    final bytes = file.readAsBytesSync();
    // A plaintext SQLite file starts with this header; an encrypted one does
    // not, because the first 16 bytes are a random salt.
    expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
    expect(String.fromCharCodes(bytes), isNot(contains('UniqueMerchantName')));
  });

  test('pubspec still selects the sqlcipher build', () {
    final pubspec =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final source = pubspec['hooks']?['user_defines']?['sqlite3']?['source'];

    expect(source, 'sqlcipher',
        reason: 'dropping this silently falls back to stock SQLite');
  });
}
