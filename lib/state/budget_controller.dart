import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/api/api.dart';
import 'package:studentos/core/api/api_client.dart';
import 'package:studentos/data/models.dart';

@immutable
class BudgetState {
  const BudgetState({
    required this.selectedMonth,
    required this.budgets,
    required this.transactions,
    required this.extraSpent,
    required this.fetchedSpent,
    required this.budgetIds,
  });

  final String selectedMonth;
  final Map<String, int> budgets;
  final List<TransactionItem> transactions;
  final Map<String, int> extraSpent;
  final Map<String, int> fetchedSpent;
  final Map<String, int> budgetIds;

  int get budget => budgets[selectedMonth] ?? 0;
  int get spent =>
      (fetchedSpent[selectedMonth] ?? 0) + (extraSpent[selectedMonth] ?? 0);
  int get remaining => budget - spent;
  double get progress =>
      budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0).toDouble();

  BudgetState copyWith({
    String? selectedMonth,
    Map<String, int>? budgets,
    List<TransactionItem>? transactions,
    Map<String, int>? extraSpent,
    Map<String, int>? fetchedSpent,
    Map<String, int>? budgetIds,
  }) => BudgetState(
    selectedMonth: selectedMonth ?? this.selectedMonth,
    budgets: budgets ?? this.budgets,
    transactions: transactions ?? this.transactions,
    extraSpent: extraSpent ?? this.extraSpent,
    fetchedSpent: fetchedSpent ?? this.fetchedSpent,
    budgetIds: budgetIds ?? this.budgetIds,
  );
}

final budgetProvider = NotifierProvider<BudgetController, BudgetState>(
  BudgetController.new,
);

class BudgetController extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    final currentMonth = _monthLabel(DateTime.now());
    return BudgetState(
      selectedMonth: currentMonth,
      budgets: Map<String, int>.unmodifiable(<String, int>{currentMonth: 0}),
      transactions: const <TransactionItem>[],
      extraSpent: const <String, int>{},
      fetchedSpent: const <String, int>{},
      budgetIds: const <String, int>{},
    );
  }

  void selectMonth(String month) =>
      state = state.copyWith(selectedMonth: month);

  void selectDate(DateTime date) {
    final month = _monthLabel(date);
    final next = <String, int>{...state.budgets};
    next.putIfAbsent(month, () => 0);
    state = state.copyWith(
      selectedMonth: month,
      budgets: Map<String, int>.unmodifiable(next),
      transactions: const <TransactionItem>[],
    );
  }

  void updateBudget(int amount) {
    if (amount <= 0) return;
    final next = <String, int>{...state.budgets, state.selectedMonth: amount};
    state = state.copyWith(budgets: Map<String, int>.unmodifiable(next));
  }

  Future<String?> saveBudget(int amount) async {
    if (amount <= 0) return 'Enter a valid budget amount';

    final (year, month) = _selectedYearMonth();
    final hasBudget = state.budgetIds[state.selectedMonth] != null;
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      hasBudget ? '${Api.userBudgets}/$year/$month' : Api.userBudgets,
      data: FormData.fromMap(
        hasBudget
            ? {'budget': amount}
            : {'year': year, 'month': month, 'budget': amount},
      ),
    );

    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['result'] == true) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final id = _asInt(data['id']);
        if (id != null) _rememberBudgetId(id);
      }
      updateBudget(amount);
      return null;
    }

    return body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'Budget update failed.'
        : response.message ?? 'Budget update failed.';
  }

  Future<String?> fetchSelectedBudget() async {
    final (year, month) = _selectedYearMonth();
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      '${Api.userBudgets}/$year/$month',
    );

    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['result'] == true &&
        body['data'] is Map<String, dynamic>) {
      final data = body['data'] as Map<String, dynamic>;
      final id = _asInt(data['id']);
      final budget = _asInt(data['budget']);
      final spent = _asInt(data['spent']);
      final transactions = _transactionsFrom(data['userExpenses']);
      final nextIds = <String, int>{...state.budgetIds};
      final nextBudgets = <String, int>{...state.budgets};
      final nextSpent = <String, int>{...state.fetchedSpent};
      if (id != null) nextIds[state.selectedMonth] = id;
      if (budget != null) nextBudgets[state.selectedMonth] = budget;
      if (spent != null) nextSpent[state.selectedMonth] = spent;
      final nextExtra = <String, int>{...state.extraSpent}
        ..remove(state.selectedMonth);
      state = state.copyWith(
        budgets: Map<String, int>.unmodifiable(nextBudgets),
        transactions: List<TransactionItem>.unmodifiable(transactions),
        extraSpent: Map<String, int>.unmodifiable(nextExtra),
        fetchedSpent: Map<String, int>.unmodifiable(nextSpent),
        budgetIds: Map<String, int>.unmodifiable(nextIds),
      );
      return null;
    }

    if (response.statusCode == 404 ||
        (body is Map<String, dynamic> &&
            (body['message']?.toString().toLowerCase().contains('not found') ??
                false))) {
      final nextIds = <String, int>{...state.budgetIds}
        ..remove(state.selectedMonth);
      final nextBudgets = <String, int>{
        ...state.budgets,
        state.selectedMonth: 0,
      };
      final nextSpent = <String, int>{...state.fetchedSpent}
        ..remove(state.selectedMonth);
      final nextExtra = <String, int>{...state.extraSpent}
        ..remove(state.selectedMonth);
      state = state.copyWith(
        budgets: Map<String, int>.unmodifiable(nextBudgets),
        transactions: const <TransactionItem>[],
        extraSpent: Map<String, int>.unmodifiable(nextExtra),
        fetchedSpent: Map<String, int>.unmodifiable(nextSpent),
        budgetIds: Map<String, int>.unmodifiable(nextIds),
      );
      return null;
    }

    return body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'Budget fetch failed.'
        : response.message ?? 'Budget fetch failed.';
  }

  Future<String?> fetchCurrentBudget() {
    selectDate(DateTime.now());
    return fetchSelectedBudget();
  }

  Future<String?> storeExpense({
    required String label,
    required String category,
    required int amount,
  }) async {
    if (label.trim().isEmpty || amount <= 0) {
      return 'Enter a description and valid amount.';
    }

    final budgetId = state.budgetIds[state.selectedMonth];
    if (budgetId == null) return 'Please add a budget first.';

    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.userExpenses,
      data: FormData.fromMap({
        'expense_type': category.trim().toLowerCase(),
        'description': label.trim(),
        'amount': amount,
        'user_budget_id': budgetId,
      }),
    );

    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['result'] == true) {
      addExpense(label: label, category: category, amount: amount);
      return null;
    }

    return body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'Expense update failed.'
        : response.message ?? 'Expense update failed.';
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

  int _monthNumber(String month) {
    const months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[month] ?? DateTime.now().month;
  }

  (int, int) _selectedYearMonth() {
    final parts = state.selectedMonth.split(' ');
    final year = parts.length > 1
        ? int.tryParse(parts.last) ?? DateTime.now().year
        : DateTime.now().year;
    return (year, _monthNumber(parts.first));
  }

  void _rememberBudgetId(int id) {
    state = state.copyWith(
      budgetIds: Map<String, int>.unmodifiable(<String, int>{
        ...state.budgetIds,
        state.selectedMonth: id,
      }),
    );
  }

  String _monthLabel(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  List<TransactionItem> _transactionsFrom(Object? source) {
    if (source is! List) return const <TransactionItem>[];
    return source
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final amount = _asInt(item['amount']) ?? 0;
          final category = item['expense_type']?.toString() ?? 'Expense';
          return TransactionItem(
            id: item['id']?.toString() ?? DateTime.now().toIso8601String(),
            emoji: '💸',
            label: item['description']?.toString() ?? category,
            category: category,
            amount: -amount.abs(),
            date: _dateLabel(item['created_at']),
          );
        })
        .toList(growable: false);
  }

  String _dateLabel(Object? value) {
    final text = value?.toString() ?? '';
    if (text.length >= 10) return text.substring(0, 10);
    return text.isEmpty ? 'Just now' : text;
  }
}
