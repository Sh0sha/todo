import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<TodoTask> _tasks = [];
  bool _showDoneTasks = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = TodoTask.decodeTasks(prefs.getStringList('tasks') ?? []);
    });
  }

  _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encodedTasks = TodoTask.encodeTasks(_tasks);
    prefs.setStringList('tasks', encodedTasks);
  }

  _addTask(TodoTask task) {
    setState(() {
      _tasks.add(task);
    });
    _saveTasks();
  }

  _updateTask(int index, TodoTask task) {
    setState(() {
      _tasks[index] = task;
    });
    _saveTasks();
  }

  _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  List<TodoTask> _filteredTasks() {
    return _showDoneTasks
        ? _tasks
        : _tasks.where((task) => !task.isDone).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showDoneTasks = !_showDoneTasks;
              });
            },
          ),
        ],
      ),
      body: _filteredTasks().isEmpty
          ? Center(child: Text('Нет задач  :('))
          : ListView.builder(
        itemCount: _filteredTasks().length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_filteredTasks()[index].title),
            subtitle: Text(_filteredTasks()[index].description),
            trailing: Checkbox(
              value: _filteredTasks()[index].isDone,
              onChanged: (value) {
                _updateTask(
                  _tasks.indexOf(_filteredTasks()[index]),
                  TodoTask(
                    title: _filteredTasks()[index].title,
                    description: _filteredTasks()[index].description,
                    isDone: value ?? false,
                  ),
                );
              },
            ),
            onTap: () async {
              final updatedTask = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(
                    task: _filteredTasks()[index],
                  ),
                ),
              );
              if (updatedTask != null) {
                _updateTask(
                  _tasks.indexOf(_filteredTasks()[index]),
                  updatedTask,
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(),
            ),
          );
          if (newTask != null) {
            _addTask(newTask);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class TodoTask {
  final String title;
  final String description;
  final bool isDone;

  TodoTask(
      {required this.title, required this.description, this.isDone = false});

  static List<String> encodeTasks(List<TodoTask> tasks) {
    return tasks.map((task) => task.toString()).toList();
  }

  static List<TodoTask> decodeTasks(List<String> encodedTasks) {
    return encodedTasks.map((encodedTask) {
      List<String> taskData = encodedTask.split(';');
      return TodoTask(
        title: taskData[0],
        description: taskData[1],
        isDone: taskData[2] == 'true',
      );
    }).toList();
  }

  @override
  String toString() {
    return '$title;$description;$isDone';
  }
}

class TaskDetailScreen extends StatefulWidget {
  final TodoTask? task;

  TaskDetailScreen({
    Key? key,
    this.task,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _isDone = widget.task?.isDone ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Задача'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Описание'),
            ),
            CheckboxListTile(
              title: Text('Выполнено'),
              value: _isDone,
              onChanged: (value) {
                setState(() {
                  _isDone = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(
            context,
            TodoTask(
              title: _titleController.text,
              description: _descriptionController.text,
              isDone: _isDone,
            ),
          );
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
