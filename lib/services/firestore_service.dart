import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

/// All Firestore reads/writes for tasks live here, scoped to a single user
/// via `users/{uid}/tasks`. Keeping this out of the providers/widgets keeps
/// business logic and data access cleanly separated.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) {
    return _db.collection('users').doc(uid).collection('tasks');
  }

  /// Real-time stream of the signed-in user's tasks, newest first.
  Stream<List<TaskModel>> streamTasks(String uid) {
    return _tasksRef(uid)
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromDoc).toList());
  }

  /// CREATE
  Future<void> addTask(TaskModel task) async {
    await _tasksRef(task.userId).add(task.toJson(useServerTimestamp: true));
  }

  /// UPDATE
  Future<void> updateTask(TaskModel task) async {
    await _tasksRef(task.userId).doc(task.id).update(task.toJson());
  }

  /// UPDATE (quick toggle, avoids re-sending the whole document)
  Future<void> toggleDone(String uid, String taskId, bool isDone) async {
    await _tasksRef(uid).doc(taskId).update({'isDone': isDone});
  }

  /// DELETE
  Future<void> deleteTask(String uid, String taskId) async {
    await _tasksRef(uid).doc(taskId).delete();
  }
}
