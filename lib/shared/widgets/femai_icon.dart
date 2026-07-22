import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';

class FemAIIcon extends StatelessWidget {
  final double size;
  final bool isSelected;
  final Color? color;

  const FemAIIcon({
    super.key, 
    this.size = 24, 
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ButterflyPainter(
          startColor: color ?? (isSelected ? FemLyraColors.aiWellness : FemLyraColors.textMuted),
          endColor: color ?? (isSelected ? FemLyraColors.primary : FemLyraColors.textMuted),
          opacity: isSelected ? 1.0 : 0.6,
        ),
      ),
    );
  }
}

class _ButterflyPainter extends CustomPainter {
  final Color startColor;
  final Color endColor;
  final double opacity;

  _ButterflyPainter({
    required this.startColor, 
    required this.endColor,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.6);

    final Paint wingPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          startColor.withValues(alpha: opacity), 
          endColor.withValues(alpha: opacity)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path wingsPath = Path();

    // Right side wings
    wingsPath.moveTo(center.dx, center.dy);
    // Upper wing
    wingsPath.cubicTo(w * 0.85, h * 0.1, w * 1.1, h * 0.5, w * 0.7, h * 0.6);
    // Lower wing
    wingsPath.cubicTo(w * 0.9, h * 0.8, w * 0.7, h * 0.95, center.dx, h * 0.8);

    // Left side wings
    wingsPath.moveTo(center.dx, center.dy);
    // Upper wing
    wingsPath.cubicTo(w * 0.15, h * 0.1, -w * 0.1, h * 0.5, w * 0.3, h * 0.6);
    // Lower wing
    wingsPath.cubicTo(w * 0.1, h * 0.8, w * 0.3, h * 0.95, center.dx, h * 0.8);

    canvas.drawPath(wingsPath, wingPaint);

    // AI Neural Connection Lines (Inside wings)
    final Paint linePaint = Paint()
      ..color = startColor.withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;

    canvas.drawLine(Offset(w * 0.4, h * 0.4), Offset(w * 0.6, h * 0.4), linePaint);
    canvas.drawLine(center, Offset(w * 0.5, h * 0.3), linePaint);

    // Neural Nodes (Dots at the tips and intersections)
    final Paint nodePaint = Paint()
      ..color = endColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Top nodes
    canvas.drawCircle(Offset(w * 0.5, h * 0.3), w * 0.05, nodePaint);
    // Antenna tips
    canvas.drawCircle(Offset(w * 0.35, h * 0.15), w * 0.04, nodePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.15), w * 0.04, nodePaint);
    
    // stylized body line
    final Paint bodyPaint = Paint()
      ..color = startColor.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(Offset(w * 0.5, h * 0.45), Offset(w * 0.5, h * 0.85), bodyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
