import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/ui/theme/app_theme.dart';
import 'package:fynans/ui/widgets/common/common.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  const options = [
    'food',
    'travel',
    'bills',
    'groceries',
    'health',
    'shopping',
    'work',
  ];

  testWidgets('shows a placeholder until values are picked', (tester) async {
    await tester.pumpWidget(
      _host(
        AppMultiSelectField(
          label: 'Tag',
          options: options,
          selected: const {},
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Any tag'), findsOneWidget);
  });

  testWidgets('renders selected values as removable chips', (tester) async {
    Set<String>? changed;
    await tester.pumpWidget(
      _host(
        AppMultiSelectField(
          label: 'Tag',
          options: options,
          selected: const {'food', 'travel'},
          onChanged: (v) => changed = v,
        ),
      ),
    );

    expect(find.text('food'), findsOneWidget);
    expect(find.text('travel'), findsOneWidget);
    expect(find.text('2 SELECTED'), findsOneWidget);

    // Removing one chip leaves the other selected.
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    expect(changed, {'travel'});
  });

  testWidgets('sheet searches and multi-selects', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      _host(
        AppMultiSelectField(
          label: 'Tag',
          options: options,
          selected: const {},
          onChanged: (v) => result = v,
        ),
      ),
    );

    await tester.tap(find.text('Any tag'));
    await tester.pumpAndSettle();

    // Search narrows the list.
    await tester.enterText(find.byType(TextField), 'gro');
    await tester.pumpAndSettle();
    expect(find.text('groceries'), findsOneWidget);
    expect(find.text('travel'), findsNothing);

    await tester.tap(find.text('groceries'));
    await tester.pumpAndSettle();

    // Clearing the query reveals everything again; pick a second value.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('travel'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Done'));
    await tester.pumpAndSettle();

    expect(result, {'groceries', 'travel'});
  });

  testWidgets('Clear returns an empty selection', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      _host(
        AppMultiSelectField(
          label: 'Tag',
          options: options,
          selected: const {'food'},
          onChanged: (v) => result = v,
        ),
      ),
    );

    await tester.tap(find.text('food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(result, isEmpty);
  });
}
