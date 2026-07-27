import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/theme/app_colors.dart';
import 'package:studentos/core/widgets/app_card.dart';
import 'package:studentos/core/widgets/common_widgets.dart';
import 'package:studentos/data/models.dart';
import 'package:studentos/state/tasks_controller.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  var _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final visible = switch (_filter) {
      _TaskFilter.all => tasks,
      _TaskFilter.active => tasks.where((item) => !item.completed).toList(),
      _TaskFilter.completed => tasks.where((item) => item.completed).toList(),
    };
    final completed = tasks.where((item) => item.completed).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: <Widget>[
          IconButton(tooltip: 'Clear completed', onPressed: completed == 0 ? null : () => ref.read(tasksProvider.notifier).clearCompleted(), icon: const Icon(Icons.cleaning_services_outlined)),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addTask(context), icon: const Icon(Icons.add_rounded), label: const Text('Add task')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: <Widget>[
          AppCard(
            color: AppColors.purpleSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Today', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 5),
                Text('$completed of ${tasks.length} tasks complete', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: tasks.isEmpty ? 0 : completed / tasks.length, minHeight: 9, borderRadius: BorderRadius.circular(999)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SegmentedButton<_TaskFilter>(
            segments: const <ButtonSegment<_TaskFilter>>[
              ButtonSegment(value: _TaskFilter.all, label: Text('All')),
              ButtonSegment(value: _TaskFilter.active, label: Text('Active')),
              ButtonSegment(value: _TaskFilter.completed, label: Text('Done')),
            ],
            selected: <_TaskFilter>{_filter},
            onSelectionChanged: (value) => setState(() => _filter = value.first),
          ),
          const SizedBox(height: 15),
          if (visible.isEmpty)
            const EmptyState(emoji: '✅', title: 'Nothing here', message: 'Add a new task or change the filter.')
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: List<Widget>.generate(visible.length, (index) {
                  final task = visible[index];
                  return Column(
                    children: <Widget>[
                      Dismissible(
                        key: ValueKey<int>(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          color: AppColors.danger,
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) => ref.read(tasksProvider.notifier).remove(task.id),
                        child: _TaskTile(task: task, onToggle: () => ref.read(tasksProvider.notifier).toggle(task.id)),
                      ),
                      if (index < visible.length - 1) const Divider(height: 1, indent: 60),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Add a task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(controller: controller, autofocus: true, textInputAction: TextInputAction.done, onSubmitted: (value) => Navigator.pop(context, value), decoration: const InputDecoration(hintText: 'What needs to be done?')),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add task')),
          ],
        ),
      ),
    );
    if (title != null) ref.read(tasksProvider.notifier).add(title);
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onToggle});

  final TaskItem task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onToggle,
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: task.completed ? AppColors.blue : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: task.completed ? AppColors.blue : Theme.of(context).colorScheme.outline, width: 2),
          ),
          child: task.completed ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
        ),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: task.completed ? TextDecoration.lineThrough : null, color: task.completed ? Theme.of(context).colorScheme.onSurfaceVariant : null)),
        trailing: const Icon(Icons.drag_handle_rounded),
      );
}

enum _TaskFilter { all, active, completed }
