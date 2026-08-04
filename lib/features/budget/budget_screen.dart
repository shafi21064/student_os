import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/theme/app_sizes.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/budget_donut.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/state/budget_controller.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetProvider);
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedMonth,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded),
                items: monthBudgets.keys
                    .map(
                      (month) => DropdownMenuItem<String>(
                        value: month,
                        child: Text(
                          month,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (month) {
                  if (month != null) {
                    ref.read(budgetProvider.notifier).selectMonth(month);
                  }
                },
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
            child: Column(
              children: expenseCategories
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

    if (amount != null) {
      ref.read(budgetProvider.notifier).updateBudget(amount);
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
                      items: expenseCategories
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.label,
                              child: Text(
                                item.label,
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

    if (submitted == true) {
      ref
          .read(budgetProvider.notifier)
          .addExpense(
            label: labelController.text.trim(),
            category: selectedCategory,
            amount: double.parse(amountController.text.trim()).round(),
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
          if (state.spent == 0)
            const EmptyState(
              emoji: '📊',
              title: 'No spending yet',
              message: 'This month has no recorded expenses.',
            )
          else
            Row(
              children: <Widget>[
                BudgetDonut(
                  budget: state.budget,
                  spent: state.spent,
                  size: 112,
                ),
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
