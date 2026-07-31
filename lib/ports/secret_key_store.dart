import 'dart:typed_data';

/// Abstract seam for storing the database encryption key outside the database.
abstract class SecretKeyStore {
  /// The stored key, or null if none has been created yet.
  Future<Uint8List?> read();

  Future<void> write(Uint8List key);
}
