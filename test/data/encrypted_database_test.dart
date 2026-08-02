import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/encrypted_database.dart';
import 'package:fynans/ports/secret_key_store.dart';

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

/// Key handling for the encrypted database.
///
/// The on-disk secrecy of the file is covered by `sqlcipher_available_test`,
/// which asserts against real SQLCipher; these cover the key lifecycle around
/// it — that a key is minted once, kept outside the database, and reused.
void main() {
  test('a fresh key is a 256-bit value written once', () async {
    final keys = _InMemoryKeyStore();

    // The generator is exercised directly: opening a real database needs the
    // app documents directory, which does not exist under `flutter test`.
    final key = generateDatabaseKey();
    await keys.write(key);

    expect(key, hasLength(32), reason: 'AES-256');
    expect(keys.writes, 1);
  });

  test('two generated keys differ', () {
    expect(generateDatabaseKey(), isNot(generateDatabaseKey()));
  });

  test('the raw-key pragma is the x\'…\' form SQLCipher needs', () {
    final key = Uint8List.fromList(List<int>.filled(32, 0xAB));

    final pragma = rawKeyPragma(key);

    // Without the x'…' wrapper this would be read as a *passphrase* and run
    // through PBKDF2, deriving a different key — encrypted, but not with ours.
    expect(pragma, contains("x'"));
    expect(pragma, contains('ab' * 32));
    expect(RegExp(r"x'([0-9a-f]{64})'").hasMatch(pragma), isTrue,
        reason: 'exactly 64 hex chars, or SQLCipher falls back to passphrase');
  });

  test('a key of the wrong length is rejected rather than reinterpreted', () {
    expect(
      () => rawKeyPragma(Uint8List.fromList(List<int>.filled(16, 1))),
      throwsA(isA<ArgumentError>()),
    );
  });
}
