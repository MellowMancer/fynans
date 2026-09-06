import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/drift_card_repository.dart';
import 'package:fynans/adapters/data/drift_card_statement_repository.dart';
import 'package:fynans/entities/credit_card.dart';

import '../fakes/fake_card_statement_repository.dart';
import 'card_statement_repository_contract.dart';

/// Runs the repository contract against both backends, registered from day
/// one — same discipline as `card_repository_contract_test.dart`, so a
/// `CardStatementRepository` divergence between the fake and Drift can never
/// go undetected the way `TransactionRepository`'s pre-existing gap allows.
void main() {
  final databases = <AppDatabase>[];

  tearDown(() async {
    for (final db in databases) {
      await db.close();
    }
    databases.clear();
  });

  runCardStatementRepositoryContract('Drift', () async {
    final db = AppDatabase(NativeDatabase.memory());
    databases.add(db);
    // With PRAGMA foreign_keys = ON, cardId must reference a real Cards row —
    // seed two (ids 1 and 2 on a fresh in-memory db) so the contract's fixed
    // cardId 1/2 resolve, same requirement
    // drift_transaction_repository_card_test.dart already established for
    // Transaction.cardId.
    final cards = DriftCardRepository(db);
    await cards.saveCard(CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..creditLimit = 50000);
    await cards.saveCard(CreditCard()
      ..issuer = 'SBI Card'
      ..last4 = '5678'
      ..creditLimit = 50000);
    return DriftCardStatementRepository(db);
  });

  runCardStatementRepositoryContract(
      'Fake', () async => FakeCardStatementRepository());
}
