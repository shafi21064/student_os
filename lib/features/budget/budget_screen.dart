import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/theme/app_colors.dart';
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
        title: const Text('Budget Manager'),
        actions: <Widget>[
          IconButton.filled(
            tooltip: 'Add expense',
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
                items: monthBudgets.keys.map((month) => DropdownMenuItem<String>(value: month, child: Text(month, style: const TextStyle(fontWeight: FontWeight.w800)))).toList(),
                onChanged: (month) {
                  if (month != null) ref.read(budgetProvider.notifier).selectMonth(month);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          _OverviewCard(state: state, onEdit: () => _showBudgetDialog(context, ref, state.budget)),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Spending by Category'),
          const SizedBox(height: 9),
          AppCard(
            child: Column(
              children: expenseCategories.map((category) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: category.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(category.label, style: const TextStyle(fontWeight: FontWeight.w700))),
                            Text('৳${category.spent}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Text('${category.percentage}%', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: category.percentage / 100,
                            minHeight: 7,
                            color: category.color,
                            backgroundColor: category.color.withValues(alpha: .12),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Recent Transactions'),
          const SizedBox(height: 9),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List<Widget>.generate(state.transactions.length, (index) {
                final item = state.transactions[index];
                return Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(15)),
                        alignment: Alignment.center,
                        child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      subtitle: Text('${item.category} · ${item.date}', style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                        '${item.amount < 0 ? '-' : '+'}৳${item.amount.abs()}',
                        style: TextStyle(color: item.amount < 0 ? AppColors.danger : AppColors.greenDark, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (index < state.transactions.length - 1) const Divider(height: 1, indent: 72),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetDialog(BuildContext context, WidgetRef ref, int current) async {
    final controller = TextEditingController(text: current.toString());
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit monthly budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '৳ ', labelText: 'Budget'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: const Text('Save')),
        ],
      ),
    );
    if (amount != null) ref.read(budgetProvider.notifier).updateBudget(amount);
  }

  Future<void> _showExpenseDialog(BuildContext context, WidgetRef ref) async {
    final label = TextEditingController();
    final amount = TextEditingController();
    var category = 'Food';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: label, autofocus: true, decoration: const InputDecoration(labelText: 'Expense name')),
              const SizedBox(height: 12),
              TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '৳ ', labelText: 'Amount')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: expenseCategories.map((item) => DropdownMenuItem<String>(value: item.label, child: Text(item.label))).toList(),
                onChanged: (value) => setState(() => category = value ?? category),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (submitted == true) {
      ref.read(budgetProvider.notifier).addExpense(label: label.text, category: category, amount: int.tryParse(amount.text) ?? 0);
    }
  }
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
              TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 17), label: const Text('Edit')),
            ],
          ),
          const SizedBox(height: 15),
          if (state.spent == 0)
            const EmptyState(emoji: '📊', title: 'No spending yet', message: 'This month has no recorded expenses.')
          else
            Row(
              children: <Widget>[
                BudgetDonut(budget: state.budget, spent: state.spent, size: 112),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('BALANCE', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w800)),
                      Text('৳$remaining', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 28)),
                      const SizedBox(height: 9),
                      Text('Budget  ৳${state.budget}', style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
                      Text('Spent    ৳${state.spent}', style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800)),
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
              color: state.progress >= .9 ? AppColors.danger : state.progress >= .7 ? AppColors.orange : AppColors.blue,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
