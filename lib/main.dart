import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TimerState { running, paused, stop }

class TaskType {
  static const work = 0;
  static const rest = 1;
}

class TaskColor {
  static const red = 0xFFFF0000;
  static const green = 0xFF00FF00;
  static const blue = 0xFF0000FF;
}

class Task {
  final String name;
  final int type;
  final int duration; // in seconds
  final int taskColor;

  Task(
      {required this.name,
      required this.type,
      required this.duration,
      required this.taskColor});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> task = {
      "name": name,
      "type": type,
      "duration": duration,
      "taskColor": taskColor
    };
    return task;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomato Bo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Tomato Bo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TimerState _timerState = TimerState.stop;
  Timer? _timer;
  List<Task> tasks = [];
  final PageController _pageController = PageController();
  int t = 0;
  static const String packageName = "com.example.tomato_bo";
  static const String filesPath = "/data/data/$packageName/files";
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void saveTask() async {
    List<Map<String, dynamic>> taskList = [];
    for (var task in tasks) {
      taskList.add(task.toMap());
    }
    ;
    final file = File("$filesPath/tasks.json");
    await file.writeAsString(jsonEncode(taskList));
    print(jsonEncode(taskList));
  }

  void _startTimer() {
    if (_timerState == TimerState.running) return;
    setState(() {
      _timerState = TimerState.running;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerState != TimerState.running) {
        timer.cancel();
        return;
      }
      setState(() {
        t--;
      });
      if (t <= 0) {
        HapticFeedback.vibrate();
        tasks.removeAt(0);
        setState(() {
          t = (tasks.isNotEmpty) ? tasks[0].duration : 0;
          _timerState = TimerState.stop;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerState = TimerState.paused;
    });
  }

  @override
  void initState() {
    super.initState();
    File("$filesPath/tasks.json").readAsString().then((s) {
      List<Task> ti = [];
      List<dynamic> decoded = jsonDecode(s);
      for (final task in decoded) {
        ti.add(Task(
            name: task["name"],
            type: task["type"],
            duration: task["duration"],
            taskColor: task["taskColor"]));
      }
      setState(() {
        tasks.addAll(ti);
        if (tasks.isNotEmpty) {
          t = tasks[0].duration;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.addchart,
                color: Colors.black,
              ))
        ],
      ),
      body: Stack(children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 70,
              ),
              CustomPaint(
                painter: ClockPainter(n: t),
                size: const Size(100, 250),
              ),
              const Text(
                "鬧鐘",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                _formatTime(t),
                style: const TextStyle(
                    fontSize: 45.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton.icon(
                label: Text((_timerState != TimerState.running) ? "開始" : "暫停"),
                onPressed: () {
                  if (_timerState == TimerState.running) {
                    _pauseTimer();
                  } else {
                    _startTimer();
                  }
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(160, 40),
                  backgroundColor: (TimerState.running != _timerState)
                      ? const Color.fromRGBO(11, 189, 184, 1.0)
                      : const Color.fromRGBO(245, 208, 118, 1.0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // <-- Radius
                  ),
                ),
              ),
            ],
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.24,
          minChildSize: 0.24,
          maxChildSize: 0.95,
          snap: true,
          expand: true,
          builder: (BuildContext context, ScrollController scrollController) {
            return Stack(
              children: [
                Container(
                    padding: const EdgeInsets.fromLTRB(12, 50, 12, 8),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        // 計算 PageView 可用的最大高度
                        // constraints.maxHeight 是 Container 內容區域的可用高度
                        final double pageViewHeight = constraints.maxHeight;

                        return SizedBox(
                          height: pageViewHeight, // 給 PageView 一個有限的高度
                          child: PageView(
                            controller: _pageController,
                            // PageView 內部的滾動將由其自身控制
                            children: [
                              // 頁面 1: 任務列表 (可垂直滾動)
                              _buildTaskListPage(scrollController),

                              // 頁面 2: 新增任務 (可垂直滾動)
                              _buildAddTaskPage(scrollController),
                            ],
                          ),
                        );
                      },
                    )),
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    // todo 4: Wrap Icon with RotationTransition widget
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 40,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ]),
    );
  }

  Widget _buildTaskListPage(ScrollController scrollController) {
    // 為了讓 DraggableScrollableSheet 的拖曳和內容滾動協同工作，
    // 我們將 PageView 內部的內容再次包裹在 SingleChildScrollView 中，
    // 並傳遞 DraggableScrollableSheet 提供的 scrollController。
    final bool isCurrentPage = _pageController.hasClients
        ? _pageController.page?.round() == 0
        : _pageController.initialPage == 0;
    return SingleChildScrollView(
      controller: isCurrentPage ? scrollController : null, // 只有在當前頁面時才使用主滾動控制器
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0, bottom: 5.0),
            child: Row(
              children: [
                const Text(
                  "任務列表",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // 點擊按鈕切換到第二頁
                IconButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // 列表內容
          for (final task in tasks)
            Dismissible(
              key: UniqueKey(),
              onDismissed: (direction) {
                setState(() {
                  tasks.remove(task);
                  // 您的 t, saveTask 邏輯...
                  if (tasks.isNotEmpty) {
                    t = tasks[0].duration;
                  } else {
                    t = 0;
                  }
                  saveTask();
                });
              },
              child: Column(
                children: [
                  Card(
                    color: Color(task.taskColor),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Text(task.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(_formatTime(t),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          const SizedBox(height: 200), // 增加一些高度來測試滾動
        ],
      ),
    );
  }

  // 新增任務頁面
  Widget _buildAddTaskPage(ScrollController scrollController) {
    // 新增任務頁面也需要包裹在 SingleChildScrollView 中，以便在表單很長時可以滾動
    final bool isCurrentPage = _pageController.hasClients
        ? _pageController.page?.round() == 1
        : _pageController.initialPage == 1;
    int _workType = 0;
    final nameTEC = TextEditingController();

    return SingleChildScrollView(
      controller: isCurrentPage ? scrollController : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 點擊返回第一頁
              IconButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const Text(
                "新增任務",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: '型別',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 0,
                      child: Text("工作"),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text("休息"),
                    )
                  ],
                  onChanged: (value) {
                    setState(() {
                      _workType = value!;
                    });
                  },
                  value: _workType,
                ),
                const SizedBox(
                  height: 20.0,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "名稱",
                    border: OutlineInputBorder(),
                  ),
                  controller: nameTEC,
                ),
                const SizedBox(
                  height: 20.0,
                ),
                const Text(
                  "  時間長度",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.black87),
                ),
                ElevatedButton.icon(
                  label:
                      const Text("新增"),
                  onPressed: () {
                    setState(() {
                      tasks.add(Task(name: nameTEC.text,type: _workType, duration: 5, taskColor: 0xFFFF0000));
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), 
                    ),
                  ),
                ),
                // ... 更多表單元件
              ],
            ),
          ),
          const SizedBox(height: 300), // 增加高度來測試滾動
        ],
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final int n;
  ClockPainter({required this.n});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0
      ..color = Colors.deepOrange;
    final circleInPaint = Paint()..color = Colors.white;
    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0
      ..color = Colors.deepOrange;
    canvas.drawLine(const Offset(15, 0), const Offset(85, 0), paint);
    canvas.drawCircle(const Offset(50, 120), 100, paint);
    canvas.drawCircle(const Offset(50, 120), 92, circleInPaint);

    //important line:70
    double d = (n % 60) * 2 * pi / 60;
    canvas.drawLine(const Offset(50, 120),
        Offset(50 + 70 * sin(d), 120 - 70 * cos(d)), linePaint);

    canvas.drawLine(const Offset(50, 25), const Offset(50, 40), linePaint);
    canvas.drawLine(const Offset(-45, 120), const Offset(-30, 120), linePaint);
    canvas.drawLine(const Offset(130, 120), const Offset(145, 120), linePaint);
    canvas.drawLine(const Offset(50, 200), const Offset(50, 215), linePaint);
    canvas.drawCircle(const Offset(50, 120), 5, paint);
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) {
    return oldDelegate.n != n;
  }
}
