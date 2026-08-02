import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/secret_key_store.dart';

const String kTransactionsBoxName = 'transactions';

/// Opens the transactions box under AES encryption.
///
/// When no key exists yet, anything already on disk is the pre-encryption box.
/// A cipher cannot open it, so it is deleted rather than migrated: SMS-derived
/// rows re-import on the next inbox sweep, and that avoids ever holding the
/// plaintext copy open alongside the encrypted one.
Future<Box<Transaction>> openTransactionBox(SecretKeyStore keys) async {
  var key = await keys.read();
  if (key == null) {
    await Hive.deleteBoxFromDisk(kTransactionsBoxName);
    key = Uint8List.fromList(Hive.generateSecureKey());
    await keys.write(key);
  }
  return Hive.openBox<Transaction>(
    kTransactionsBoxName,
    encryptionCipher: HiveAesCipher(key),
  );
}
