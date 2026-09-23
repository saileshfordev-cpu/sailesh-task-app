import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) {
    return _db.collection('users').doc(uid).collection('tasks');
  }

  Stream<List<TaskModel>> streamTasks(String uid) {
    return _tasksRef(uid)
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromDoc).toList());
  }

  Future<void> addTask(TaskModel task) async {
    await _tasksRef(task.userId).add(task.toJson(useServerTimestamp: true));
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasksRef(task.userId).doc(task.id).update(task.toJson());
  }

  Future<void> toggleDone(String uid, String taskId, bool isDone) async {
    await _tasksRef(uid).doc(taskId).update({'isDone': isDone});
  }

  Future<void> toggleStar(String uid, String taskId, bool isStarred) async {
    await _tasksRef(uid).doc(taskId).update({'isStarred': isStarred});
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _tasksRef(uid).doc(taskId).delete();
  }
}
