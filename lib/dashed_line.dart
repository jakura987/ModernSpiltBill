import 'package:flutter/material.dart';

class DashedLine extends StatelessWidget {
  final double height;
  final Color color;
  final double width;

  const DashedLine({
    this.height = 1,
    this.color = Colors.green,
    required this.width, // 将width设为必需的
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashPainter(color: color, height: height),
      size: Size(width, height), // 这里使用传入的width
    );
  }
}


class DashPainter extends CustomPainter {
  final double height;
  final Color color;

  DashPainter({required this.color, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5.0;
    double dashSpace = 5.0;
    double startX = 0.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = height;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
