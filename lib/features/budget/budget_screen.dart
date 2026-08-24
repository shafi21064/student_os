import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/budget_donut.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/state/budget_controller.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(budgetProvider.notifier).fetchSelectedBudget();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetProvider);
    final categoryRows = _categoryRows(state);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.budgetManager),
        actions: <Widget>[
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
            ),
            tooltip: AppStrings.addExpense,
            onPressed: () => _showExpenseDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickBudgetMonth(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.calendar_month_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.selectedMonth,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _OverviewCard(
            state: state,
            onEdit: () => _showBudgetDialog(context, ref, state.budget),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: AppStrings.spendingByCategory),
          const SizedBox(height: 9),
          AppCard(
            child: categoryRows.isEmpty
                ? const EmptyState(
                    emoji: '📊',
                    title: 'No expenses yet',
                    message: 'This month has no recorded expenses.',
                  )
                : Column(
                    children: categoryRows
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: category.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        category.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '৳${category.spent}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${category.percentage}%',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: category.percentage / 100,
                                    minHeight: 7,
                                    color: category.color,
                                    backgroundColor: category.color.withValues(
                                      alpha: .12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: AppStrings.recentTransactions),
          const SizedBox(height: 9),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List<Widget>.generate(state.transactions.length, (
                index,
              ) {
                final item = state.transactions[index];
                return Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      title: Text(
                        item.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${item.category} · ${item.date}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        '${item.amount < 0 ? '-' : '+'}৳${item.amount.abs()}',
                        style: TextStyle(
                          color: item.amount < 0
                              ? AppColors.danger
                              : AppColors.greenDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (index < state.transactions.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBudgetMonth(BuildContext context) async {
    final state = ref.read(budgetProvider);
    final picked = await _showMonthPicker(
      context,
      initialDate: _dateFromMonthLabel(state.selectedMonth),
    );
    if (picked == null || !context.mounted) return;
    ref.read(budgetProvider.notifier).selectDate(picked);
    await ref.read(budgetProvider.notifier).fetchSelectedBudget();
  }

  Future<void> _showBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toString() : '',
    );

    String? errorText;

    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void saveBudget() {
              final value = int.tryParse(
                controller.text.trim().replaceAll(',', ''),
              );

              if (value == null || value <= 0) {
                setDialogState(() {
                  errorText = 'Enter a valid budget amount';
                });
                return;
              }

              Navigator.pop(dialogContext, value);
            }

            return _BudgetDialogPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    AppStrings.addBudget,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() {
                          errorText = null;
                        });
                      }
                    },
                    onSubmitted: (_) => saveBudget(),
                    decoration: _budgetInputDecoration(
                      hintText: AppStrings.amount,
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _BudgetPrimaryButton(
                    label: AppStrings.addBudget,
                    onPressed: saveBudget,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (amount != null && context.mounted) {
      final error = await ref.read(budgetProvider.notifier).saveBudget(amount);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Budget updated successfully.')),
      );
    }
  }

  Future<void> _showExpenseDialog(BuildContext context, WidgetRef ref) async {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    var selectedCategory = 'Food';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _BudgetDialogPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                AppStrings.addExpense,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: labelController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: _budgetInputDecoration(
                  hintText: AppStrings.description,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _budgetInputDecoration(
                        hintText: AppStrings.amount,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.unfold_more_rounded),
                      decoration: _budgetInputDecoration(),
                      items: _expenseTypes
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedCategory = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _BudgetPrimaryButton(
                label: AppStrings.addExpense,
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim());
                  if (labelController.text.trim().isEmpty ||
                      amount == null ||
                      amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a description and valid amount.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted == true && context.mounted) {
      final error = await ref
          .read(budgetProvider.notifier)
          .storeExpense(
            label: labelController.text.trim(),
            category: selectedCategory,
            amount: double.parse(amountController.text.trim()).round(),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Expense added successfully.')),
      );
    }
  }
}

class _BudgetDialogPanel extends StatelessWidget {
  const _BudgetDialogPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 620),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    ),
  );
}

class _BudgetPrimaryButton extends StatelessWidget {
  const _BudgetPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 64,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}

InputDecoration _budgetInputDecoration({String? hintText, String? errorText}) {
  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    hintStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: AppColors.muted,
    ),
    filled: true,
    fillColor: AppColors.inputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 21),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
  );
}

const _monthNames = <String>[
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

const _expenseTypes = <String>['Food', 'Transport', 'Books', 'Bills', 'Other'];

List<_CategorySpend> _categoryRows(BudgetState state) {
  final totals = <String, int>{};
  for (final item in state.transactions) {
    totals.update(
      item.category,
      (value) => value + item.amount.abs(),
      ifAbsent: () => item.amount.abs(),
    );
  }
  final spent = totals.values.fold<int>(0, (sum, value) => sum + value);
  if (totals.isEmpty) {
    return const <_CategorySpend>[];
  }
  var index = 0;
  return totals.entries
      .map((entry) {
        final color = _categoryColors[index % _categoryColors.length];
        index++;
        return _CategorySpend(
          label: entry.key,
          spent: entry.value,
          percentage: spent == 0 ? 0 : ((entry.value / spent) * 100).round(),
          color: color,
        );
      })
      .toList(growable: false);
}

const _categoryColors = <Color>[
  AppColors.orange,
  AppColors.blue,
  AppColors.purple,
  AppColors.green,
  AppColors.teal,
];

class _CategorySpend {
  const _CategorySpend({
    required this.label,
    required this.spent,
    required this.percentage,
    required this.color,
  });

  final String label;
  final int spent;
  final int percentage;
  final Color color;
}

Future<DateTime?> _showMonthPicker(
  BuildContext context, {
  required DateTime initialDate,
}) {
  var year = initialDate.year;
  var month = initialDate.month;
  final now = DateTime.now();
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.purpleSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select month',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Previous year',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setDialogState(() => year--),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '$year',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next year',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setDialogState(() => year++),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.9,
                ),
                itemCount: _monthNames.length,
                itemBuilder: (context, index) {
                  final value = index + 1;
                  return _MonthTile(
                    label: _monthNames[index],
                    selected: value == month,
                    current: year == now.year && value == now.month,
                    onTap: () => setDialogState(() => month = value),
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(dialogContext, DateTime(year, month)),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.label,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.brand
        : current
        ? AppColors.green
        : AppColors.border;
    final background = selected
        ? AppColors.brand
        : current
        ? AppColors.greenSoft
        : AppColors.inputBackground;
    final foreground = selected ? Colors.white : AppColors.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Stack(
            children: <Widget>[
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              if (current)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _dateFromMonthLabel(String label) {
  final parts = label.split(' ');
  final now = DateTime.now();
  final month = parts.isNotEmpty
      ? _monthNames.indexOf(parts.first) + 1
      : now.month;
  final year = parts.length > 1
      ? int.tryParse(parts.last) ?? now.year
      : now.year;
  return DateTime(year, month == 0 ? now.month : month);
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.state, required this.onEdit});

  final BudgetState state;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final remaining = state.remaining.clamp(0, 999999999);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('My Budget', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              BadgeLabel(state.selectedMonth),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: <Widget>[
              BudgetDonut(budget: state.budget, spent: state.spent, size: 112),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'BALANCE',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '৳$remaining',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Budget  ৳${state.budget}',
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Spent    ৳${state.spent}',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 9,
              color: state.progress >= .9
                  ? AppColors.danger
                  : state.progress >= .7
                  ? AppColors.orange
                  : AppColors.blue,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
