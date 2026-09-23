import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory { personal, work, shopping, health, other }

TaskPriority priorityFromString(String? value) {
  switch (value) {
    case 'high': return TaskPriority.high;
    case 'low': return TaskPriority.low;
    default: return TaskPriority.medium;
  }
}

TaskCategory categoryFromString(String? value) {
  switch (value) {
    case 'work': return TaskCategory.work;
    case 'shopping': return TaskCategory.shopping;
    case 'health': return TaskCategory.health;
    case 'other': return TaskCategory.other;
    default: return TaskCategory.personal;
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final bool isStarred;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String userId;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.isStarred,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.userId,
    this.dueDate,
  });

  bool get isOverdue => dueDate != null && !isDone && dueDate!.isBefore(DateTime.now());

  factory TaskModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TaskModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      isDone: (data['isDone'] as bool?) ?? false,
      isStarred: (data['isStarred'] as bool?) ?? false,
      priority: priorityFromString(data['priority'] as String?),
      category: categoryFromString(data['category'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      userId: (data['userId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson({bool useServerTimestamp = false}) {
    return {
      'title': title,
      'description': description,
      'isDone': isDone,
      'isStarred': isStarred,
      'priority': priority.name,
      'category': category.name,
      'createdAt': useServerTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'userId': userId,
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    bool? isDone,
    bool? isStarred,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      isStarred: isStarred ?? this.isStarred,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      userId: userId,
    );
  }
}
