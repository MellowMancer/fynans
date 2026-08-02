import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fynans/ports/secret_key_store.dart';

/// [SecretKeyStore] backed by the platform keystore.
///
/// The key must not live in the box it protects, nor in SharedPreferences —
/// on Android this delegates to the hardware-backed Keystore, so the key is
/// not readable even with the app's own data directory in hand.
class KeystoreSecretKeyStore implements SecretKeyStore {
  const KeystoreSecretKeyStore();

  static const String _keyName = 'transactions_box_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<Uint8List?> read() async {
    final encoded = await _storage.read(key: _keyName);
    return encoded == null ? null : base64Decode(encoded);
  }

  @override
  Future<void> write(Uint8List key) =>
      _storage.write(key: _keyName, value: base64Encode(key));
}
