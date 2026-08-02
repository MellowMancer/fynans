import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Removes the pre-Drift Hive box left behind on upgrading devices.
///
/// Its rows were never migrated — SMS-derived ones re-import from the inbox —
/// so the file is dead weight holding the user's transaction history in a
/// store nothing reads. Deliberately does *not* touch the keystore entry:
/// that key now protects the Drift database.
Future<void> deleteLegacyHiveBox({Directory? in_}) async {
  final directory = in_ ?? await getApplicationDocumentsDirectory();
  for (final name in ['transactions.hive', 'transactions.lock']) {
    final file = File('${directory.path}/$name');
    if (file.existsSync()) await file.delete();
  }
}
