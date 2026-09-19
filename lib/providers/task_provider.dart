import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

/// Filter applied to the visible task list on the Home screen.
enum TaskFilter { all, active, done }

/// Owns the real-time task list for the current user and exposes CRUD
/// actions. Widgets subscribe via [context.watch]/[Consumer] and never talk
/// to Firestore directly.
class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  TaskProvider({FirestoreService? firestoreService}) : _firestoreService = firestoreService ?? FirestoreService();

  StreamSubscription<List<TaskModel>>? _sub;
  List<TaskModel> _tasks = [];
  bool isLoading = true;
  String? errorMessage;
  TaskFilter filter = TaskFilter.all;
  String? _uid;

  List<TaskModel> get tasks {
    switch (filter) {
      case TaskFilter.active:
        return _tasks.where((t) => !t.isDone).toList();
      case TaskFilter.done:
        return _tasks.where((t) => t.isDone).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  int get doneCount => _tasks.where((t) => t.isDone).length;
  int get totalCount => _tasks.length;

  /// Call once the user's uid is known (typically from AuthGate) to start
  /// listening to their tasks. Safe to call repeatedly — it only
  /// resubscribes when the uid actually changes.
  void bindToUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _tasks = [];

    if (uid == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    _sub = _firestoreService.streamTasks(uid).listen(
      (tasks) {
        _tasks = tasks;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = 'Could not load tasks. Pull to refresh or check your connection.';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void setFilter(TaskFilter newFilter) {
    filter = newFilter;
    notifyListeners();
  }

  Future<void> addTask({
    required String uid,
    required String title,
    required String description,
    required TaskPriority priority,
  }) async {
    final task = TaskModel(
      id: '',
      title: title.trim(),
      description: description.trim(),
      isDone: false,
      priority: priority,
      createdAt: DateTime.now(),
      userId: uid,
    );
    await _firestoreService.addTask(task);
  }

  Future<void> updateTask(TaskModel task) async {
    await _firestoreService.updateTask(task);
  }

  Future<void> toggleDone(TaskModel task) async {
    await _firestoreService.toggleDone(task.userId, task.id, !task.isDone);
  }

  Future<void> deleteTask(TaskModel task) async {
    await _firestoreService.deleteTask(task.userId, task.id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
