import 'package:flutter/material.dart';
import '../config/theme.dart';

class PerspectiveGridBackground extends StatelessWidget {
  final Widget child;

  const PerspectiveGridBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PerspectiveGridPainter(),
      child: child,
    );
  }
}

class _PerspectiveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.velocityBorder.withValues(alpha: 0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Horizon line Y (vanishing zone slightly above mid-height)
    final horizonY = size.height * 0.22;
    final vanishingPointX = size.width * 0.5;

    // 1. Perspective longitudinal lines converging upwards
    const int verticalCount = 14;
    final double spreadBottom = size.width * 1.6;
    final double startXBottom = (size.width - spreadBottom) / 2;
    final double bottomStep = spreadBottom / (verticalCount - 1);

    for (int i = 0; i < verticalCount; i++) {
      final bx = startXBottom + (i * bottomStep);
      final tx = vanishingPointX + (bx - vanishingPointX) * 0.35;

      canvas.drawLine(
        Offset(tx, horizonY),
        Offset(bx, size.height * 0.85),
        linePaint,
      );
    }

    // 2. Horizontal perspective cross-lines with exponential spacing
    const int horizontalCount = 10;
    for (int i = 1; i <= horizontalCount; i++) {
      final t = (i / horizontalCount);
      // Exponential / quad easing for perspective distance
      final y = horizonY + (size.height * 0.63) * (t * t);

      // Fade lines near horizon
      final alpha = (0.2 + (0.65 * t)).clamp(0.0, 0.85);
      final horizPaint = Paint()
        ..color = AppTheme.velocityBorder.withValues(alpha: alpha)
        ..strokeWidth = 1.0;

      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y),
        horizPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
