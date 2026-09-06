import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/drift_card_repository.dart';

import '../fakes/fake_card_repository.dart';
import 'card_repository_contract.dart';

/// Runs the repository contract against both backends — unlike
/// `TransactionRepository`'s contract (Drift-only, a pre-existing gap), this
/// one is registered against the fake from day one so it can never silently
/// diverge from what CardsCubit actually exercises in the cubit/bloc tests.
void main() {
  final databases = <AppDatabase>[];

  tearDown(() async {
    for (final db in databases) {
      await db.close();
    }
    databases.clear();
  });

  runCardRepositoryContract('Drift', () async {
    final db = AppDatabase(NativeDatabase.memory());
    databases.add(db);
    return DriftCardRepository(db);
  });

  runCardRepositoryContract('Fake', () async => FakeCardRepository());
}
