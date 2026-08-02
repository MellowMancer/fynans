import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/drift_transaction_repository.dart';
import 'package:fynans/adapters/data/hive_transaction_repository.dart';
import 'package:fynans/adapters/data/transaction_box.dart';
import 'package:fynans/adapters/data/transaction_hive_adapter.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:hive/hive.dart';

import 'transaction_repository_contract.dart';

/// Runs one contract against both backends.
///
/// Passing here is the gate for rewiring the app: it says the two are
/// interchangeable, rather than hoping so after the swap.
void main() {
  group('Hive', () {
    late Directory dir;
    late Box<Transaction> box;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TransactionAdapter());
      }
    });

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fynans_contract_hive');
      Hive.init(dir.path);
      box = await Hive.openBox<Transaction>(kTransactionsBoxName);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    runTransactionRepositoryContract(
      'Hive',
      () async => HiveTransactionRepository(),
    );
  });

  group('Drift', () {
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
  });
}
