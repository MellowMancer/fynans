import 'package:mocktail/mocktail.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// Shared mocktail double, so each bloc test does not declare its own.
class MockTransactionRepository extends Mock implements TransactionRepository {}
