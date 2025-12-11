import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});
  @override
  Widget build(BuildContext context) {
    var data = [10,30];
    return Scaffold(
      appBar: AppBar(
        title: const Text('數據分析'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CustomPaint(
                  painter: ChartPainter(),
                  size: const Size(100,200),
                ),
                Row(
                  children: [
                    for (var day in data) 
                      Bar(value: day,)
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class Bar extends StatefulWidget {
  const Bar({required this.value});
  final int value;

  @override
  State<StatefulWidget> createState() => _BarState();
}

class _BarState extends State<Bar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(12),
          child: Container(
              decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              height: _animation.value,
              width: 15.0),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = Tween<double>(begin: 0, end: widget.value * 8)
        .animate(_animationController);
    _animationController.forward();
  }
}

class ChartPainter extends CustomPainter {
  ChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0
      ..color = Colors.black;
    canvas.drawLine(const Offset(10, 10), Offset(10, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
