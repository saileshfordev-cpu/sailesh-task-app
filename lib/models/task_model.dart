import 'package:cloud_firestore/cloud_firestore.dart';

/// Priority levels for a task — drives the color accent shown on each tile.
enum TaskPriority { low, medium, high }

TaskPriority priorityFromString(String? value) {
  switch (value) {
    case 'high':
      return TaskPriority.high;
    case 'low':
      return TaskPriority.low;
    default:
      return TaskPriority.medium;
  }
}

/// Core data model for a single task document stored in Firestore under
/// `users/{uid}/tasks/{taskId}`.
class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final TaskPriority priority;
  final DateTime createdAt;
  final String userId;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.priority,
    required this.createdAt,
    required this.userId,
  });

  /// Builds a [TaskModel] from a Firestore document snapshot.
  factory TaskModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TaskModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      isDone: (data['isDone'] as bool?) ?? false,
      priority: priorityFromString(data['priority'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: (data['userId'] as String?) ?? '',
    );
  }

  /// Converts this task into a Firestore-writable map.
  /// `createdAt` uses a server timestamp so ordering is consistent
  /// regardless of the client's clock.
  Map<String, dynamic> toJson({bool useServerTimestamp = false}) {
    return {
      'title': title,
      'description': description,
      'isDone': isDone,
      'priority': priority.name,
      'createdAt': useServerTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    bool? isDone,
    TaskPriority? priority,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      userId: userId,
    );
  }
}
