import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/exercise_model.dart';
import 'exercise_types.dart';

class ExerciseVideoBanner extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseVideoBanner({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final videoUrl = exercise.videoUrl ?? exercise.gifUrl;
    final muscleColor = getMuscleColor(exercise.muscleGroup);

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoUrl != null)
              Image.network(
                videoUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.velocityLime,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Loading demonstration video...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('[ExerciseMedia] Error loading video demo: $videoUrl: $error');
                  return buildVisualPreviewFallback(exercise, muscleColor);
                },
              )
            else
              buildVisualPreviewFallback(exercise, muscleColor),

            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      size: 14,
                      color: AppTheme.velocityLime,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'DEMONSTRATION VIDEO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
