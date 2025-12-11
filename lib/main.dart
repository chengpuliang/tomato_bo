import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tomato_bo/analysis.dart';
import 'package:tomato_bo/task_service.dart';

enum TimerState { running, paused, stopped }

class TaskType {
  static const work = 0;
  static const rest = 1;
}

class TaskColor {
  static const yellow = 0xFFEDCB77;
  static const green = 0xFF63C1BD;
  static const red = 0xFFE4645B;
  static const purple = 0xFF92ACE5;
  static const deepBlue = 0xFF5595C4;
  static const lightBlue = 0xFF579ECF;
  static const colorList = [yellow, green, red, purple, deepBlue, lightBlue];
}

class Task {
  final String name;
  final int type;
  final int duration;
  final int taskColor;

  Task(
      {required this.name,
      required this.type,
      required this.duration,
      required this.taskColor});

  Map<String, dynamic> toMap() => {
        "name": name,
        "type": type,
        "duration": duration,
        "taskColor": taskColor
      };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        name: m['name'] ?? '',
        type: (m['type'] ?? TaskType.work) as int,
        duration: (m['duration'] ?? 0) as int,
        taskColor: (m['taskColor'] ?? TaskColor.red) as int,
      );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final taskService = TaskService();
  await taskService.loadTasks();
  runApp(MyApp(taskService: taskService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.taskService});
  final TaskService taskService;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomato Bo',
      debugShowCheckedModeBanner: false, //Disable debug banner on top right
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Tomato Bo',
        taskService: taskService,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.taskService});
  final String title;
  final TaskService taskService;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  TimerState _timerState = TimerState.stopped;
  Timer? _timer;
  final PageController _pageController = PageController();
  final DraggableScrollableController _draggableScrollableController =
      DraggableScrollableController();
  final ValueNotifier<int> t = ValueNotifier<int>(0);
  late AnimationController _clockAniCtrl;
  late Animation<double> _clockAnimation;
  int? colorGroupValue = TaskColor.colorList.first;
  int workType = 0;
  final nameTEC = TextEditingController();
  final minTEC = TextEditingController();
  final secTEC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    if (_timerState == TimerState.running) return;
    if (t.value <= 0) return;
    _clockAniCtrl.stop();
    setState(() {
      _timerState = TimerState.running;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      t.value -= 1;
      if (t.value <= 0) {
        HapticFeedback.vibrate();
        _clockAniCtrl.repeat(reverse: true);
        widget.taskService.removeAt(0);
        setState(() {
          updateTimer();
          _timerState = TimerState.stopped;
          _timer?.cancel();
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

  void updateTimer() {
    setState(() {
      t.value = (widget.taskService.tasks.isNotEmpty)
          ? widget.taskService.tasks[0].duration
          : 0;
    });
  }

  @override
  void initState() {
    updateTimer();
    super.initState();
    _clockAniCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _clockAnimation =
        Tween<double>(begin: -pi / 12, end: pi / 12).animate(_clockAniCtrl);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _draggableScrollableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title),
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const AnalysisPage();
                  }));
                },
                icon: const ImageIcon(
                  AssetImage("assets/analysis.png"),
                  size: 20.0,
                ),
              )),
        ],
      ),
      body: Stack(children: [
        Center(
          child: Column(
            children: <Widget>[
              const SizedBox(
                height: 70,
              ),
              AnimatedBuilder(
                  animation: _clockAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: (_clockAniCtrl.isAnimating)
                          ? _clockAnimation.value
                          : 0,
                      child: ValueListenableBuilder(
                          valueListenable: t,
                          builder: (context, value, child) {
                            return CustomPaint(
                              painter: ClockPainter(n: t.value),
                              size: const Size(100, 250),
                            );
                          }),
                    );
                  }),
              const SizedBox(
                height: 45,
              ),
              const Text(
                "鬧鐘",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              ValueListenableBuilder(
                  valueListenable: t,
                  builder: (context, value, child) {
                    return Text(
                      _formatTime(value),
                      style: const TextStyle(
                          fontSize: 45.0, fontWeight: FontWeight.bold),
                    );
                  }),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton.icon(
                label: Text(switch (_timerState) {
                  TimerState.stopped => "開始",
                  TimerState.paused => "繼續",
                  TimerState.running => "暫停",
                }),
                onPressed: (t.value <= 0)
                    ? null
                    : () {
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        DraggableScrollableSheet(
          controller: _draggableScrollableController,
          initialChildSize: 0.2,
          minChildSize: 0.2,
          maxChildSize: 0.95,
          snap: true,
          builder: (BuildContext context, ScrollController scrollController) {
            return Stack(
              children: [
                Container(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
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
                          (BuildContext context, BoxConstraints constraints) =>
                              PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildTaskListPage(
                              scrollController, _draggableScrollableController),
                          _buildAddTaskPage(scrollController),
                        ],
                      ),
                    )),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      // todo 4: Wrap Icon with RotationTransition widget
                      child: Container(
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(32)),
                            color: Colors.black12),
                        height: 6.0,
                        width: 60.0,
                      )),
                ),
              ],
            );
          },
        ),
      ]),
    );
  }

  Widget _buildTaskListPage(ScrollController scrollController,
      DraggableScrollableController draggableScrollableController) {
    return Column(
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
              IconButton(
                onPressed: () {
                  setState(() {
                    widget.taskService.add(Task(
                        name: "範例任務",
                        type: TaskType.work,
                        duration: 5,
                        taskColor: TaskColor.red));
                    widget.taskService.add(Task(
                        name: "範例任務2",
                        type: TaskType.work,
                        duration: 6,
                        taskColor: TaskColor.green));
                    widget.taskService.add(Task(
                        name: "範例任務3",
                        type: TaskType.work,
                        duration: 7,
                        taskColor: TaskColor.deepBlue));
                    updateTimer();
                  });
                },
                icon: const Icon(Icons.adobe_rounded),
              ),
              IconButton(
                onPressed: () {
                  draggableScrollableController
                      .animateTo(
                    0.95,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  )
                      .whenComplete(() {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        // 列表內容
        if (widget.taskService.tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "目前沒有任務，請新增任務。",
              style: TextStyle(color: Colors.black54),
            ),
          ),
        Expanded(
            child: ReorderableListView.builder(
                scrollController: scrollController,
                itemBuilder: (context, index) {
                  final task = widget.taskService.tasks[index];
                  return Dismissible(
                    key: ObjectKey(task),
                    onDismissed: (direction) {
                      setState(() {
                        if (widget.taskService.tasks.first == task) {
                          _timerState = TimerState.stopped;
                          _timer?.cancel();
                          widget.taskService.remove(task);
                          updateTimer();
                        } else {
                          widget.taskService.remove(task);
                        }
                      });
                    },
                    child: Column(
                      children: [
                        const SizedBox(height: 7),
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
                                Text(_formatTime(task.duration),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                    ),
                  );
                },
                itemCount: widget.taskService.tasks.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final task = widget.taskService.tasks.removeAt(oldIndex);
                    widget.taskService.tasks.insert(newIndex, task);
                    widget.taskService.saveTasks();
                    if (oldIndex == 0 || newIndex == 0) {
                      _timerState = TimerState.stopped;
                      _timer?.cancel();
                      updateTimer();
                    }
                  });
                }))
      ],
    );
  }

  // 新增任務頁面
  Widget _buildAddTaskPage(ScrollController scrollController) {
    return SingleChildScrollView(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "  型別",
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
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
                          workType = value!;
                        });
                      },
                      value: workType,
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    const Text(
                      "  名稱",
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "請輸入名稱",
                        border: OutlineInputBorder(),
                      ),
                      controller: nameTEC,
                      validator: (value) {
                        return value!.isEmpty ? "名稱為必填欄位" : null;
                      },
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    const Text(
                      "  時間長度",
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            controller: minTEC,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              return value!.isEmpty ? "必填欄位" : null;
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 15.0,
                        ),
                        const Text(
                          ":",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 32.0),
                        ),
                        const SizedBox(
                          width: 15.0,
                        ),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            controller: secTEC,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              return value!.isEmpty ? "必填欄位" : null;
                            },
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 32.0,
                    ),
                    const Text(
                      "  顏色",
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Row(
                      children: [
                        for (var color in TaskColor.colorList)
                          Radio<int>(
                            value: color,
                            groupValue: colorGroupValue,
                            onChanged: (int? value) {
                              setState(() {
                                colorGroupValue = color;
                              });
                            },
                            fillColor: WidgetStatePropertyAll(Color(color)),
                          )
                      ],
                    ),
                    const SizedBox(
                      height: 32.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 45.0,
                      child: ElevatedButton.icon(
                        label: const Text("新增"),
                        onPressed: () {
                          if ((formKey.currentState as FormState).validate()) {
                            setState(() {
                              widget.taskService.tasks.add(Task(
                                  name: nameTEC.text,
                                  type: workType,
                                  duration: 60 * int.parse(minTEC.text) +
                                      int.parse(secTEC.text),
                                  taskColor: colorGroupValue!));
                              widget.taskService.saveTasks();
                              if (widget.taskService.tasks.length == 1) {
                                updateTimer();
                              }
                            });
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
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
