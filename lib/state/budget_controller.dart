import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';

@immutable
class BudgetState {
  const BudgetState({
    required this.selectedMonth,
    required this.budgets,
    required this.transactions,
    required this.extraSpent,
  });

  final String selectedMonth;
  final Map<String, int> budgets;
  final List<TransactionItem> transactions;
  final Map<String, int> extraSpent;

  int get budget => budgets[selectedMonth] ?? 8000;
  int get spent =>
      (monthSpent[selectedMonth] ?? 0) + (extraSpent[selectedMonth] ?? 0);
  int get remaining => budget - spent;
  double get progress =>
      budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0).toDouble();

  BudgetState copyWith({
    String? selectedMonth,
    Map<String, int>? budgets,
    List<TransactionItem>? transactions,
    Map<String, int>? extraSpent,
  }) => BudgetState(
    selectedMonth: selectedMonth ?? this.selectedMonth,
    budgets: budgets ?? this.budgets,
    transactions: transactions ?? this.transactions,
    extraSpent: extraSpent ?? this.extraSpent,
  );
}

final budgetProvider = NotifierProvider<BudgetController, BudgetState>(
  BudgetController.new,
);

class BudgetController extends Notifier<BudgetState> {
  @override
  BudgetState build() => BudgetState(
    selectedMonth: 'Jul 2025',
    budgets: Map<String, int>.unmodifiable(monthBudgets),
    transactions: List<TransactionItem>.unmodifiable(initialTransactions),
    extraSpent: const <String, int>{},
  );

  void selectMonth(String month) =>
      state = state.copyWith(selectedMonth: month);

  void updateBudget(int amount) {
    if (amount <= 0) return;
    final next = <String, int>{...state.budgets, state.selectedMonth: amount};
    state = state.copyWith(budgets: Map<String, int>.unmodifiable(next));
  }

  void addExpense({
    required String label,
    required String category,
    required int amount,
  }) {
    if (label.trim().isEmpty || amount <= 0) return;
    final transaction = TransactionItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      emoji: '💸',
      label: label.trim(),
      category: category,
      amount: -amount.abs(),
      date: 'Just now',
    );
    state = state.copyWith(
      transactions: List<TransactionItem>.unmodifiable(<TransactionItem>[
        transaction,
        ...state.transactions,
      ]),
      extraSpent: Map<String, int>.unmodifiable(<String, int>{
        ...state.extraSpent,
        state.selectedMonth:
            (state.extraSpent[state.selectedMonth] ?? 0) + amount.abs(),
      }),
    );
  }
}
