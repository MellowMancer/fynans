import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/drift_transaction_repository.dart';

import '../fakes/fake_transaction_repository.dart';
import 'transaction_repository_contract.dart';

/// Runs the repository contract against both backends, so that the fake that
/// most of the suite uses is held to the same rules as Drift.
void main() {
  final databases = <AppDatabase>[];

  tearDown(() async {
    for (final db in databases) {
      await db.close();
    }
    databases.clear();
  });

  runTransactionRepositoryContract('Drift', () async {
    final db = AppDatabase(NativeDatabase.memory());
    databases.add(db);
    return DriftTransactionRepository(db);
  });

  runTransactionRepositoryContract(
      'Fake', () async => FakeTransactionRepository());
}
