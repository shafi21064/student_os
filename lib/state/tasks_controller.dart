import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/api/api.dart';
import 'package:studentos/core/api/api_client.dart';
import 'package:studentos/data/models.dart';

final tasksProvider = NotifierProvider<TasksController, List<TaskItem>>(
  TasksController.new,
);

class TasksController extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() => const <TaskItem>[];

  void toggleLocal(int id) {
    state = <TaskItem>[
      for (final task in state)
        if (task.id == id) task.copyWith(completed: !task.completed) else task,
    ];
  }

  Future<String?> updateTodoStatus(int id) async {
    final task = state.where((item) => item.id == id).firstOrNull;
    if (task == null) return 'Todo not found.';
    final nextCompleted = !task.completed;
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '${Api.userTodos}/$id',
      data: FormData.fromMap({'status': nextCompleted ? 'done' : 'pending'}),
    );

    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['result'] == true) {
      state = <TaskItem>[
        for (final item in state)
          if (item.id == id) item.copyWith(completed: nextCompleted) else item,
      ];
      return null;
    }

    return body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'Todo update failed.'
        : response.message ?? 'Todo update failed.';
  }

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final nextId = state.isEmpty
        ? 1
        : state.map((item) => item.id).reduce((a, b) => a > b ? a : b) + 1;
    state = <TaskItem>[
      ...state,
      TaskItem(id: nextId, title: trimmed, completed: false),
    ];
  }

  Future<String?> storeTodo(String description) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return 'Enter a task description.';

    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.userTodos,
      data: FormData.fromMap({'description': trimmed}),
    );

    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['result'] == true) {
      final data = body['data'];
      final id = data is Map<String, dynamic> ? _asInt(data['id']) : null;
      state = <TaskItem>[
        ...state,
        TaskItem(
          id:
              id ??
              (state.isEmpty
                  ? 1
                  : state
                            .map((item) => item.id)
                            .reduce((a, b) => a > b ? a : b) +
                        1),
          title: trimmed,
          completed: false,
        ),
      ];
      return null;
    }

    return body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'Todo update failed.'
        : response.message ?? 'Todo update failed.';
  }

  Future<String?> fetchTodos() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      Api.userTodos,
    );

    final body = response.data;
    if (response.isSuccess && body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final pending = _tasksFrom(data['pending'], completed: false);
        final done = _tasksFrom(data['done'], completed: true);
        state = List<TaskItem>.unmodifiable(<TaskItem>[...pending, ...done]);
        return null;
      }
    }

    return body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'Todo fetch failed.'
        : response.message ?? 'Todo fetch failed.';
  }

  void remove(int id) {
    state = state.where((task) => task.id != id).toList(growable: false);
  }

  void clearCompleted() {
    state = state.where((task) => !task.completed).toList(growable: false);
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  List<TaskItem> _tasksFrom(Object? source, {required bool completed}) {
    if (source is! List) return const <TaskItem>[];
    return source
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final status = item['status']?.toString();
          return TaskItem(
            id: _asInt(item['id']) ?? 0,
            title: item['description']?.toString() ?? '',
            completed: status == null ? completed : status == 'done',
          );
        })
        .where((item) => item.title.isNotEmpty)
        .toList(growable: false);
  }
}
