import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Task Model
class Task {
  final String title;
  final String description;

  Task({required this.title, required this.description});

  Map<String, dynamic> toJson() => {'title': title, 'description': description};

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(title: json['title'], description: json['description']);
  }
}

// Task Cubit for State Management
class TaskCubit extends Cubit<List<Task>> {
  final Box box;

  TaskCubit(this.box) : super([]) {
    loadTasks();
  }

  void loadTasks() {
    final tasks = box.get('tasks', defaultValue: []) as List<dynamic>;
    emit(tasks.map((e) => Task.fromJson(e)).toList());
  }

  void addTask(Task task) {
    final updatedTasks = List<Task>.from(state)..add(task);
    box.put('tasks', updatedTasks.map((e) => e.toJson()).toList());
    emit(updatedTasks);
  }

  void updateTask(int index, Task updatedTask) {
    final updatedTasks = List<Task>.from(state);
    updatedTasks[index] = updatedTask;
    box.put('tasks', updatedTasks.map((e) => e.toJson()).toList());
    emit(updatedTasks);
  }

  void deleteTask(int index) {
    final updatedTasks = List<Task>.from(state)..removeAt(index);
    box.put('tasks', updatedTasks.map((e) => e.toJson()).toList());
    emit(updatedTasks);
  }
}

// Main Application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('tasksBox');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Web CRUD',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BlocProvider(create: (_) => TaskCubit(box), child: TaskScreen()),
    );
  }
}

// Task Screen UI
class TaskScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskCubit = context.read<TaskCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Web CRUD')),
      body: BlocBuilder<TaskCubit, List<Task>>(
        builder: (context, tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks added yet.'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed:
                            () => _showEditTaskDialog(context, index, task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => taskCubit.deleteTask(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final taskCubit = context.read<TaskCubit>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isNotEmpty && description.isNotEmpty) {
                  final newTask = Task(title: title, description: description);
                  taskCubit.addTask(newTask);
                  titleController.clear();
                  descriptionController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, int index, Task task) {
    final taskCubit = context.read<TaskCubit>();
    titleController.text = task.title;
    descriptionController.text = task.description;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isNotEmpty && description.isNotEmpty) {
                  final updatedTask = Task(
                    title: title,
                    description: description,
                  );
                  taskCubit.updateTask(index, updatedTask);
                  titleController.clear();
                  descriptionController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
