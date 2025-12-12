import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});
  @override
  Widget build(BuildContext context) {
    var data = [10, 30, 25, 17, 24, 23, 14];
    final double paddingVal = ((MediaQuery.sizeOf(context).width - 165.0)/7)-6;
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
                  size: Size( MediaQuery.sizeOf(context).width, 280),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                  child: Row(
                    children: [
                      for (var day in data)
                        Bar(
                          value: day,padding: paddingVal,
                        )
                    ],
                  ),
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
  const Bar({required this.value, required this.padding});
  final int value;
  final double padding;

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
          padding: EdgeInsets.fromLTRB(widget.padding, 277-_animation.value, 0, 0),
          child: Container(
              decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight: Radius.circular(12))),
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
      ..strokeWidth = 6.0
      ..color = Colors.black;
    canvas.drawLine(const Offset(50, 10), Offset(50, size.height), paint);
    canvas.drawLine(Offset(50, size.height-50), Offset(size.width-50, size.height-50), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
