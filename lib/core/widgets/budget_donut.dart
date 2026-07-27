import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studentos/core/theme/app_colors.dart';

class BudgetDonut extends StatelessWidget {
  const BudgetDonut({
    required this.budget,
    required this.spent,
    super.key,
    this.size = 108,
  });

  final int budget;
  final int spent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0).toDouble();
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BudgetDonutPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              Text('spent', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetDonutPainter extends CustomPainter {
  const _BudgetDonutPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final stroke = radius * 0.28;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.green;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: <Color>[AppColors.blue, AppColors.purple]).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, backgroundPaint);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(_BudgetDonutPainter oldDelegate) => oldDelegate.progress != progress;
}
