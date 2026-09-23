import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

enum TaskFilter { all, active, done, starred, overdue }
enum TaskSort { newest, oldest, priority, dueDate }

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  TaskProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  StreamSubscription<List<TaskModel>>? _sub;
  List<TaskModel> _tasks = [];
  bool isLoading = true;
  String? errorMessage;
  TaskFilter filter = TaskFilter.all;
  TaskSort sort = TaskSort.newest;
  String searchQuery = '';
  TaskCategory? categoryFilter;
  String? _uid;

  // For undo delete
  TaskModel? _lastDeleted;

  List<TaskModel> get tasks {
    List<TaskModel> result = List.from(_tasks);

    // Search
    if (searchQuery.isNotEmpty) {
      result = result.where((t) =>
          t.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    // Category filter
    if (categoryFilter != null) {
      result = result.where((t) => t.category == categoryFilter).toList();
    }

    // Filter
    switch (filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isDone).toList();
        break;
      case TaskFilter.done:
        result = result.where((t) => t.isDone).toList();
        break;
      case TaskFilter.starred:
        result = result.where((t) => t.isStarred).toList();
        break;
      case TaskFilter.overdue:
        result = result.where((t) => t.isOverdue).toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Sort — starred always on top, then by sort
    result.sort((a, b) {
      if (a.isStarred && !b.isStarred) return -1;
      if (!a.isStarred && b.isStarred) return 1;
      switch (sort) {
        case TaskSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case TaskSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case TaskSort.priority:
          return b.priority.index.compareTo(a.priority.index);
        case TaskSort.dueDate:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
      }
    });

    return result;
  }

  int get doneCount => _tasks.where((t) => t.isDone).length;
  int get totalCount => _tasks.length;
  int get starredCount => _tasks.where((t) => t.isStarred).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

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
        errorMessage = 'Could not load tasks. Pull to refresh.';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void setFilter(TaskFilter newFilter) {
    filter = newFilter;
    notifyListeners();
  }

  void setSort(TaskSort newSort) {
    sort = newSort;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(TaskCategory? cat) {
    categoryFilter = cat;
    notifyListeners();
  }

  Future<void> addTask({
    required String uid,
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskCategory category,
    DateTime? dueDate,
  }) async {
    final task = TaskModel(
      id: '',
      title: title.trim(),
      description: description.trim(),
      isDone: false,
      isStarred: false,
      priority: priority,
      category: category,
      createdAt: DateTime.now(),
      dueDate: dueDate,
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

  Future<void> toggleStar(TaskModel task) async {
    await _firestoreService.toggleStar(task.userId, task.id, !task.isStarred);
  }

  Future<void> deleteTask(TaskModel task) async {
    _lastDeleted = task;
    await _firestoreService.deleteTask(task.userId, task.id);
  }

  Future<void> undoDelete() async {
    if (_lastDeleted == null) return;
    await _firestoreService.addTask(_lastDeleted!);
    _lastDeleted = null;
  }

  bool get canUndo => _lastDeleted != null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
