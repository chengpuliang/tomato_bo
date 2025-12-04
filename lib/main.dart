import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TimerState { running, paused, stop }

enum TaskType { work, rest }

class TaskColor {
  static const red = Colors.red;
  static const green = Colors.green;
  static const blue = Colors.blue;
}

class Task {
  final String name;
  final TaskType type;
  final int duration; // in seconds
  final MaterialColor taskColor;

  Task(
      {required this.name,
      required this.type,
      required this.duration,
      required this.taskColor});
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
  List<Task> tasks = [
    Task(
        name: "Study Math",
        type: TaskType.work,
        duration: 2,
        taskColor: TaskColor.red),
    Task(
        name: "Short Break",
        type: TaskType.rest,
        duration: 3,
        taskColor: TaskColor.green),
    Task(
        name: "Study Science",
        type: TaskType.work,
        duration: 4,
        taskColor: TaskColor.red),
    Task(
        name: "Long Break",
        type: TaskType.rest,
        duration: 5,
        taskColor: TaskColor.blue),
  ];
  int t = 0;
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
    if (tasks.isNotEmpty) {
      t = tasks[0].duration;
    }
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
                  padding: const EdgeInsets.fromLTRB(12, 100, 12, 8),
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
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        for (final task in tasks)
                          Dismissible(
                              key: UniqueKey(),
                              onDismissed: (direction) {
                                setState(() {
                                  tasks.remove(task);
                                  if (tasks.isNotEmpty) {
                                    t = tasks[0].duration;
                                  } else {
                                    t = 0;
                                  }
                                });
                              },
                              child: Column(
                                children: [
                                  Card(
                                    color: task.taskColor,
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
                                  const SizedBox(
                                    height: 15,
                                  ),
                                ],
                              )),
                      ],
                    ),
                  ),
                ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
                  child: Row(
                    children: [
                      const Text(
                        "任務列表",
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.add))
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ]),
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
