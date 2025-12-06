import 'dart:convert';
import 'package:tomato_bo/main.dart';
import 'dart:io';

class TaskService {
  final List<Task> tasks = [];
  final String taskFilePath =
      "/data/data/com.example.tomato_bo/files/tasks.json";
  Future<void> saveTasks() async {
    final file = File(taskFilePath);
    await file.writeAsString(jsonEncode(tasks.map((t) => t.toMap()).toList()));
  }
  Future<void> loadTasks() async {
    final file = File(taskFilePath);
    if (await file.exists() == false) return;
    file.readAsString().then((s) {
      List<dynamic> decoded = jsonDecode(s);
      tasks
        ..clear()
        ..addAll(decoded.map((t) => Task.fromMap(t)));
    });
  }

  void remove(Task task) {
    tasks.remove(task);
    saveTasks();
  }

  void add(Task task) {
    tasks.add(task);
    saveTasks();
  }

  void removeAt(int index) {
    tasks.removeAt(index);
    saveTasks();
  }
}
