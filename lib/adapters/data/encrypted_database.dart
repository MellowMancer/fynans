import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/ports/secret_key_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

const String kDatabaseFileName = 'fynans.db';

/// Thrown when the connection is not actually encrypted.
///
/// There is no safe degraded mode: a plain SQLite build accepts every
/// statement and silently ignores `PRAGMA key`, so failing to detect this
/// means writing financial data in the clear with no other symptom.
class DatabaseNotEncrypted extends StateError {
  DatabaseNotEncrypted(super.message);
}

/// Opens the encrypted transactions database.
///
/// When no key exists yet, any database already on disk cannot be opened, so
/// it is deleted rather than migrated — the same stance the Hive box takes.
Future<AppDatabase> openEncryptedDatabase(SecretKeyStore keys) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$kDatabaseFileName');

  var key = await keys.read();
  if (key == null) {
    await _deleteDatabase(file);
    key = _generateKey();
    await keys.write(key);
  }

  final pragma = _rawKeyPragma(key);
  return AppDatabase(NativeDatabase(file, setup: (db) => _configure(db, pragma)));
}

/// A fresh 256-bit key from the platform CSPRNG.
Uint8List _generateKey() {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(32, (_) => random.nextInt(256)),
  );
}

/// The raw-key form. `PRAGMA key = '<hex>'` without the `x'...'` wrapper is a
/// *passphrase*, which SQLCipher would run through PBKDF2 to derive a
/// different key — encrypted, but not with the key we hold.
String _rawKeyPragma(Uint8List key) {
  if (key.length != 32) {
    throw ArgumentError('Expected a 32-byte key, got ${key.length}.');
  }
  final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return "PRAGMA key = \"x'$hex'\";";
}

/// Runs before Drift issues any statement of its own.
void _configure(CommonDatabase db, String keyPragma) {
  // Must be first: anything Drift runs on an unkeyed connection (it starts with
  // PRAGMA user_version) would create a plaintext page.
  db.execute(keyPragma);

  // On plain SQLite this returns ZERO ROWS rather than throwing, because
  // unknown pragmas are silently ignored. Emptiness is the signal.
  if (db.select('PRAGMA cipher_version;').isEmpty) {
    throw DatabaseNotEncrypted(
      'SQLCipher is not loaded; the database would be written in plaintext.',
    );
  }

  // Surfaces a wrong key as SQLITE_NOTADB now, rather than when Drift later
  // tries to migrate a database it cannot read.
  db.select('SELECT count(*) FROM sqlite_master;');

  // Keep spilled sort/DISTINCT b-trees in memory so they never land unencrypted.
  db.execute('PRAGMA temp_store = 2;');
}

Future<void> _deleteDatabase(File file) async {
  for (final path in [file.path, '${file.path}-wal', '${file.path}-shm']) {
    final sidecar = File(path);
    if (sidecar.existsSync()) await sidecar.delete();
  }
}
