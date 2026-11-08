import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Gold arch-and-book mark used on the splash and login screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _QuranMarkPainter()),
    );
  }
}

class _QuranMarkPainter extends CustomPainter {
  const _QuranMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final arch = Path()
      ..moveTo(w * 0.20, h * 0.84)
      ..lineTo(w * 0.20, h * 0.46)
      ..cubicTo(w * 0.20, h * 0.16, w * 0.36, h * 0.06, w * 0.50, h * 0.06)
      ..cubicTo(w * 0.64, h * 0.06, w * 0.80, h * 0.16, w * 0.80, h * 0.46)
      ..lineTo(w * 0.80, h * 0.84);
    canvas.drawPath(arch, stroke);

    final book = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pages = Path()
      ..moveTo(w * 0.30, h * 0.58)
      ..quadraticBezierTo(w * 0.40, h * 0.46, w * 0.50, h * 0.54)
      ..quadraticBezierTo(w * 0.60, h * 0.46, w * 0.70, h * 0.58)
      ..lineTo(w * 0.70, h * 0.78)
      ..quadraticBezierTo(w * 0.60, h * 0.68, w * 0.50, h * 0.76)
      ..quadraticBezierTo(w * 0.40, h * 0.68, w * 0.30, h * 0.78)
      ..close();
    canvas.drawPath(pages, book);
    canvas.drawLine(
      Offset(w * 0.50, h * 0.54),
      Offset(w * 0.50, h * 0.76),
      book,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
