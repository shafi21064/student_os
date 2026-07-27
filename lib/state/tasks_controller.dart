import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';

final tasksProvider = NotifierProvider<TasksController, List<TaskItem>>(TasksController.new);

class TasksController extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() => List<TaskItem>.unmodifiable(initialTasks);

  void toggle(int id) {
    state = <TaskItem>[
      for (final task in state)
        if (task.id == id)
          task.copyWith(completed: !task.completed)
        else
          task,
    ];
  }

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final nextId = state.isEmpty ? 1 : state.map((item) => item.id).reduce((a, b) => a > b ? a : b) + 1;
    state = <TaskItem>[...state, TaskItem(id: nextId, title: trimmed, completed: false)];
  }

  void remove(int id) {
    state = state.where((task) => task.id != id).toList(growable: false);
  }

  void clearCompleted() {
    state = state.where((task) => !task.completed).toList(growable: false);
  }
}
