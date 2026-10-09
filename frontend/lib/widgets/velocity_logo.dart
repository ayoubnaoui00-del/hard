import 'package:flutter/material.dart';
import '../config/theme.dart';

class VelocityLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String title;

  const VelocityLogo({
    super.key,
    this.size = 28,
    this.showText = true,
    this.title = 'HARD',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _VelocityIconPainter(),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: AppTheme.velocityTextPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _VelocityIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Titanium white vertical / angled polygon
    final whitePaint = Paint()
      ..color = AppTheme.velocityTextPrimary
      ..style = PaintingStyle.fill;

    // Electric lime horizontal / angled polygon
    final limePaint = Paint()
      ..color = AppTheme.velocityLime
      ..style = PaintingStyle.fill;

    final darkRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.15, w * 0.38, h * 0.7),
      const Radius.circular(3.5),
    );

    final limeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.25, h * 0.45, w * 0.75, h * 0.4),
      const Radius.circular(3.5),
    );

    canvas.drawRRect(darkRRect, whitePaint);
    canvas.drawRRect(limeRRect, limePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
