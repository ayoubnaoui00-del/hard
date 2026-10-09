import 'package:flutter/material.dart';
import 'body_map_models.dart';

/// CustomPainter rendering an anatomical human silhouette with color-coded muscle zones
class BodyMapPainter extends CustomPainter {
  final MuscleGroupType selectedMuscle;
  final bool isFront;

  BodyMapPainter({
    required this.selectedMuscle,
    required this.isFront,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final basePaint = Paint()
      ..color = const Color(0xFF2B3340)
      ..style = PaintingStyle.fill;

    final baseBorderPaint = Paint()
      ..color = const Color(0xFF424D5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Head & Neck Silhouette
    final headRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.08),
      width: size.width * 0.18,
      height: size.height * 0.12,
    );
    canvas.drawOval(headRect, basePaint);
    canvas.drawOval(headRect, baseBorderPaint);

    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.15),
        width: size.width * 0.11,
        height: size.height * 0.06,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(neckRect, basePaint);

    if (isFront) {
      _paintFront(canvas, size, centerX);
    } else {
      _paintBack(canvas, size, centerX);
    }
  }

  Paint _getMusclePaint(MuscleGroupType muscle, {bool isAccent = false}) {
    final isSelected = selectedMuscle == muscle;
    return Paint()
      ..color = isSelected
          ? muscle.color.withValues(alpha: isAccent ? 0.95 : 0.8)
          : muscle.color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
  }

  Paint _getMuscleBorder(MuscleGroupType muscle) {
    final isSelected = selectedMuscle == muscle;
    return Paint()
      ..color = isSelected ? muscle.color : muscle.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.0;
  }

  void _paintFront(Canvas canvas, Size size, double centerX) {
    // Shoulders
    final leftShoulder = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(centerX - size.width * 0.28, size.height * 0.22),
        width: size.width * 0.18,
        height: size.height * 0.10,
      ));
    final rightShoulder = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(centerX + size.width * 0.28, size.height * 0.22),
        width: size.width * 0.18,
        height: size.height * 0.10,
      ));
    final shoulderPaint = _getMusclePaint(MuscleGroupType.shoulders);
    final shoulderBorder = _getMuscleBorder(MuscleGroupType.shoulders);
    canvas.drawPath(leftShoulder, shoulderPaint);
    canvas.drawPath(leftShoulder, shoulderBorder);
    canvas.drawPath(rightShoulder, shoulderPaint);
    canvas.drawPath(rightShoulder, shoulderBorder);

    // Chest
    final leftPec = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.22, size.height * 0.19, size.width * 0.21, size.height * 0.11),
      const Radius.circular(8),
    );
    final rightPec = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.01, size.height * 0.19, size.width * 0.21, size.height * 0.11),
      const Radius.circular(8),
    );
    final chestPaint = _getMusclePaint(MuscleGroupType.chest);
    final chestBorder = _getMuscleBorder(MuscleGroupType.chest);
    canvas.drawRRect(leftPec, chestPaint);
    canvas.drawRRect(leftPec, chestBorder);
    canvas.drawRRect(rightPec, chestPaint);
    canvas.drawRRect(rightPec, chestBorder);

    // Core
    final corePaint = _getMusclePaint(MuscleGroupType.core);
    final coreBorder = _getMuscleBorder(MuscleGroupType.core);
    for (int row = 0; row < 3; row++) {
      final y = size.height * 0.32 + (row * size.height * 0.05);
      final leftAb = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - size.width * 0.14, y, size.width * 0.13, size.height * 0.042),
        const Radius.circular(4),
      );
      final rightAb = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + size.width * 0.01, y, size.width * 0.13, size.height * 0.042),
        const Radius.circular(4),
      );
      canvas.drawRRect(leftAb, corePaint);
      canvas.drawRRect(leftAb, coreBorder);
      canvas.drawRRect(rightAb, corePaint);
      canvas.drawRRect(rightAb, coreBorder);
    }

    // Arms
    final armsPaint = _getMusclePaint(MuscleGroupType.arms);
    final armsBorder = _getMuscleBorder(MuscleGroupType.arms);
    final leftBicep = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.39, size.height * 0.28, size.width * 0.11, size.height * 0.12),
      const Radius.circular(8),
    );
    final rightBicep = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.28, size.height * 0.28, size.width * 0.11, size.height * 0.12),
      const Radius.circular(8),
    );
    final leftForearm = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.42, size.height * 0.41, size.width * 0.09, size.height * 0.13),
      const Radius.circular(6),
    );
    final rightForearm = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.33, size.height * 0.41, size.width * 0.09, size.height * 0.13),
      const Radius.circular(6),
    );
    canvas.drawRRect(leftBicep, armsPaint);
    canvas.drawRRect(leftBicep, armsBorder);
    canvas.drawRRect(rightBicep, armsPaint);
    canvas.drawRRect(rightBicep, armsBorder);
    canvas.drawRRect(leftForearm, armsPaint);
    canvas.drawRRect(leftForearm, armsBorder);
    canvas.drawRRect(rightForearm, armsPaint);
    canvas.drawRRect(rightForearm, armsBorder);

    // Legs
    final legsPaint = _getMusclePaint(MuscleGroupType.legs);
    final legsBorder = _getMuscleBorder(MuscleGroupType.legs);
    final leftQuad = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.21, size.height * 0.50, size.width * 0.19, size.height * 0.24),
      const Radius.circular(10),
    );
    final rightQuad = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.02, size.height * 0.50, size.width * 0.19, size.height * 0.24),
      const Radius.circular(10),
    );
    final leftCalf = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.18, size.height * 0.77, size.width * 0.14, size.height * 0.18),
      const Radius.circular(8),
    );
    final rightCalf = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.04, size.height * 0.77, size.width * 0.14, size.height * 0.18),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftQuad, legsPaint);
    canvas.drawRRect(leftQuad, legsBorder);
    canvas.drawRRect(rightQuad, legsPaint);
    canvas.drawRRect(rightQuad, legsBorder);
    canvas.drawRRect(leftCalf, legsPaint);
    canvas.drawRRect(leftCalf, legsBorder);
    canvas.drawRRect(rightCalf, legsPaint);
    canvas.drawRRect(rightCalf, legsBorder);
  }

  void _paintBack(Canvas canvas, Size size, double centerX) {
    final backPaint = _getMusclePaint(MuscleGroupType.back);
    final backBorder = _getMuscleBorder(MuscleGroupType.back);

    // Upper Back
    final upperBack = Path()
      ..moveTo(centerX - size.width * 0.22, size.height * 0.18)
      ..lineTo(centerX + size.width * 0.22, size.height * 0.18)
      ..lineTo(centerX + size.width * 0.15, size.height * 0.32)
      ..lineTo(centerX - size.width * 0.15, size.height * 0.32)
      ..close();
    canvas.drawPath(upperBack, backPaint);
    canvas.drawPath(upperBack, backBorder);

    // Lats
    final leftLat = Path()
      ..moveTo(centerX - size.width * 0.25, size.height * 0.24)
      ..lineTo(centerX - size.width * 0.05, size.height * 0.26)
      ..lineTo(centerX - size.width * 0.05, size.height * 0.44)
      ..lineTo(centerX - size.width * 0.15, size.height * 0.42)
      ..close();
    final rightLat = Path()
      ..moveTo(centerX + size.width * 0.25, size.height * 0.24)
      ..lineTo(centerX + size.width * 0.05, size.height * 0.26)
      ..lineTo(centerX + size.width * 0.05, size.height * 0.44)
      ..lineTo(centerX + size.width * 0.15, size.height * 0.42)
      ..close();
    canvas.drawPath(leftLat, backPaint);
    canvas.drawPath(leftLat, backBorder);
    canvas.drawPath(rightLat, backPaint);
    canvas.drawPath(rightLat, backBorder);

    // Triceps
    final armsPaint = _getMusclePaint(MuscleGroupType.arms);
    final armsBorder = _getMuscleBorder(MuscleGroupType.arms);
    final leftTricep = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.39, size.height * 0.26, size.width * 0.11, size.height * 0.14),
      const Radius.circular(8),
    );
    final rightTricep = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.28, size.height * 0.26, size.width * 0.11, size.height * 0.14),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftTricep, armsPaint);
    canvas.drawRRect(leftTricep, armsBorder);
    canvas.drawRRect(rightTricep, armsPaint);
    canvas.drawRRect(rightTricep, armsBorder);

    // Glutes & Hamstrings & Calves
    final legsPaint = _getMusclePaint(MuscleGroupType.legs);
    final legsBorder = _getMuscleBorder(MuscleGroupType.legs);
    final leftGlute = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.19, size.height * 0.47, size.width * 0.18, size.height * 0.12),
      const Radius.circular(10),
    );
    final rightGlute = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.01, size.height * 0.47, size.width * 0.18, size.height * 0.12),
      const Radius.circular(10),
    );
    final leftHamstring = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.20, size.height * 0.60, size.width * 0.18, size.height * 0.15),
      const Radius.circular(8),
    );
    final rightHamstring = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.02, size.height * 0.60, size.width * 0.18, size.height * 0.15),
      const Radius.circular(8),
    );
    final leftCalfBack = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.18, size.height * 0.77, size.width * 0.14, size.height * 0.18),
      const Radius.circular(8),
    );
    final rightCalfBack = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.04, size.height * 0.77, size.width * 0.14, size.height * 0.18),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftGlute, legsPaint);
    canvas.drawRRect(leftGlute, legsBorder);
    canvas.drawRRect(rightGlute, legsPaint);
    canvas.drawRRect(rightGlute, legsBorder);
    canvas.drawRRect(leftHamstring, legsPaint);
    canvas.drawRRect(leftHamstring, legsBorder);
    canvas.drawRRect(rightHamstring, legsPaint);
    canvas.drawRRect(rightHamstring, legsBorder);
    canvas.drawRRect(leftCalfBack, legsPaint);
    canvas.drawRRect(leftCalfBack, legsBorder);
    canvas.drawRRect(rightCalfBack, legsPaint);
    canvas.drawRRect(rightCalfBack, legsBorder);
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle || oldDelegate.isFront != isFront;
  }
}
