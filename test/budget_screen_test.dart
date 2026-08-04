import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/features/budget/budget_screen.dart';

void main() {
  testWidgets('adding an expense updates the visible budget balance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BudgetScreen())),
    );

    await tester.tap(find.byTooltip(AppStrings.addExpense));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Lunch');
    await tester.enterText(find.byType(TextField).at(1), '300');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Expense'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('৳2500'), findsOneWidget);
  });
}
