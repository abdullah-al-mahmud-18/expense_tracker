import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:expense_tracker/models/expense_period.dart';
import 'package:expense_tracker/models/expense_type.dart';
import 'package:expense_tracker/models/imported_row.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/home_page.dart';
import 'package:expense_tracker/services/expense_repository.dart';

/// In-memory stand-in for [ExpenseRepository] so the widget test never
/// touches the real sqflite plugin (no platform channel in the test host).
class FakeExpenseRepository implements ExpenseRepository {
  @override
  Future<ExpensePeriod> getCurrentPeriod() async {
    return ExpensePeriod(id: 1, startedAt: DateTime.now());
  }

  @override
  Future<List<ExpensePeriod>> getPreviousPeriods() async => [];

  @override
  Future<void> addExpense(String type, double amount) async {}

  @override
  Future<void> closeCurrentPeriod() async {}

  @override
  Future<void> clearOldestPreviousPeriods(int count) async {}

  @override
  Future<void> replaceAllData(List<ImportedExpenseRow> rows) async {}

  @override
  Future<List<ExpenseType>> getExpenseTypes() async => const [
    ExpenseType(id: 1, name: 'fare'),
    ExpenseType(id: 2, name: 'grocery'),
  ];

  @override
  Future<void> addExpenseType(String name) async {}

  @override
  Future<void> renameExpenseType(int id, String name) async {}

  @override
  Future<void> deleteExpenseType(int id) async {}
}

void main() {
  testWidgets('Home page renders command input and close button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ExpenseProvider(repository: FakeExpenseRepository()),
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'close'), findsOneWidget);

    final closeButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'close'),
    );
    expect(closeButton.onPressed, isNull);
  });

  testWidgets('Typing shows matching expense type suggestions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ExpenseProvider(repository: FakeExpenseRepository()),
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'g');
    await tester.pumpAndSettle();
    expect(find.text('grocery'), findsOneWidget);
    expect(find.text('fare'), findsNothing);

    await tester.tap(find.text('grocery'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'grocery ');
  });
}
