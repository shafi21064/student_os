import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/constants/app_strings.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/state/tasks_controller.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _controller = TextEditingController();
  var _filter = _TaskFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final done = tasks.where((item) => item.completed).length;
    final visible = switch (_filter) {
      _TaskFilter.all => tasks,
      _TaskFilter.pending => tasks.where((item) => !item.completed).toList(),
      _TaskFilter.done => tasks.where((item) => item.completed).toList(),
    };

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text(AppStrings.todo),
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton.filledTonal(
            tooltip: AppStrings.back,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Row(
            children: <Widget>[
              _StatCard(
                label: AppStrings.total,
                value: tasks.length,
                color: Colors.white,
                valueColor: AppColors.ink,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: AppStrings.pending,
                value: tasks.length - done,
                color: AppColors.orangeSoft,
                valueColor: AppColors.warning,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: AppStrings.done,
                value: done,
                color: AppColors.greenSoft,
                valueColor: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            radius: 16,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTask(),
                    decoration: InputDecoration(
                      hintText: AppStrings.addNewTask,
                      hintStyle: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brand),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(62, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text(AppStrings.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _FilterButton(
                label: AppStrings.all,
                selected: _filter == _TaskFilter.all,
                onTap: () => setState(() => _filter = _TaskFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: AppStrings.pending,
                selected: _filter == _TaskFilter.pending,
                onTap: () => setState(() => _filter = _TaskFilter.pending),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: AppStrings.done,
                selected: _filter == _TaskFilter.done,
                onTap: () => setState(() => _filter = _TaskFilter.done),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            radius: 16,
            padding: EdgeInsets.zero,
            child: visible.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: <Widget>[
                        Text('✅', style: TextStyle(fontSize: 34)),
                        SizedBox(height: 8),
                        Text(
                          'No tasks here!',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: List<Widget>.generate(visible.length, (index) {
                      final task = visible[index];
                      return Column(
                        children: <Widget>[
                          _TaskRow(
                            task: task,
                            onToggle: () => ref
                                .read(tasksProvider.notifier)
                                .toggle(task.id),
                            onRemove: () => ref
                                .read(tasksProvider.notifier)
                                .remove(task.id),
                          ),
                          if (index < visible.length - 1)
                            const Divider(height: 1, color: AppColors.canvas),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    ref.read(tasksProvider.notifier).add(_controller.text);
    _controller.clear();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.valueColor,
  });

  final String label;
  final int value;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppCard(
      radius: 16,
      color: color,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onRemove,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: <Widget>[
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: task.completed ? AppColors.blue : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: task.completed ? AppColors.blue : AppColors.border,
                width: 2,
              ),
            ),
            child: task.completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              color: task.completed ? AppColors.border : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: task.completed ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.border,
              decorationThickness: 2,
            ),
          ),
        ),
        IconButton(
          tooltip: AppStrings.deleteTask,
          onPressed: onRemove,
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          icon: const Icon(Icons.close_rounded, color: AppColors.border),
        ),
      ],
    ),
  );
}

enum _TaskFilter { all, pending, done }
