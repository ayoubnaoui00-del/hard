import 'package:flutter/material.dart';

class SegmentedProgressBar extends StatelessWidget {
  final int totalSegments;
  final int completedSegments;
  final Color activeColor;
  final Color inactiveColor;
  final bool hasStripedCurrent;
  final double height;

  const SegmentedProgressBar({
    super.key,
    required this.totalSegments,
    required this.completedSegments,
    required this.activeColor,
    this.inactiveColor = const Color(0xFFE5EDE3),
    this.hasStripedCurrent = false,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(totalSegments, (index) {
          final isCompleted = index < completedSegments;
          final isNextCurrent = hasStripedCurrent && index == completedSegments;

          Widget segmentWidget;

          if (isCompleted) {
            segmentWidget = Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            );
          } else if (isNextCurrent) {
            segmentWidget = ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: CustomPaint(
                painter: _StripedSegmentPainter(
                  baseColor: inactiveColor,
                  stripeColor: activeColor.withValues(alpha: 0.65),
                ),
              ),
            );
          } else {
            segmentWidget = Container(
              decoration: BoxDecoration(
                color: inactiveColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            );
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < totalSegments - 1 ? 4.0 : 0.0,
              ),
              child: segmentWidget,
            ),
          );
        }),
      ),
    );
  }
}

class _StripedSegmentPainter extends CustomPainter {
  final Color baseColor;
  final Color stripeColor;

  _StripedSegmentPainter({
    required this.baseColor,
    required this.stripeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Diagonal stripes (45 degrees)
    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const double step = 6.0;
    final double maxDim = size.width + size.height;

    for (double x = -size.height; x < maxDim; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
