import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/adapters/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/ui/screens/transactions_list_screen.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/utils/formatters.dart';

import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());
  tearDown(() => repository.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RepositoryProvider<TransactionRepository>.value(
          value: repository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<TransactionCubit>(
                create: (context) => TransactionCubit(repository),
              ),
              BlocProvider<AdvancedViewBloc>(
                create: (context) =>
                    AdvancedViewBloc(repository)..add(AdvancedViewDataFetched()),
              ),
            ],
            child: const TransactionsListScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Swiping right moves the pager one month back.
  Future<void> swipeToPreviousMonth(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
  }

  Future<void> tapMode(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'the month stays put across a round trip through the advanced view',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);

    final now = DateTime.now();
    final thisMonth = Fmt.monthYear(DateTime(now.year, now.month));
    final previousMonth = Fmt.monthYear(DateTime(now.year, now.month - 1));

    expect(find.text(thisMonth), findsOneWidget);

    await swipeToPreviousMonth(tester);
    expect(find.text(previousMonth), findsOneWidget);

    // Switching modes used to destroy the pager, which rebuilt from its
    // initialPage — header on the latest month, list on the swiped-to one.
    await tapMode(tester, 'Advanced');
    await tapMode(tester, 'Simple');

    expect(find.text(previousMonth), findsOneWidget);
    expect(find.text(thisMonth), findsNothing);
  });
}
