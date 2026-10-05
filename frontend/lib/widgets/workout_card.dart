import 'package:flutter/material.dart';
import '../config/theme.dart';

class VelocityWorkoutCardData {
  final String id;
  final String firstLine;
  final List<String> highlightedPhrases;
  final String lastLine;
  final Color highlightColor;
  final String imageAsset;
  final List<String> bulletPoints;
  final VoidCallback onStart;

  const VelocityWorkoutCardData({
    required this.id,
    required this.firstLine,
    required this.highlightedPhrases,
    required this.lastLine,
    required this.highlightColor,
    required this.imageAsset,
    required this.bulletPoints,
    required this.onStart,
  });
}

class VelocityWorkoutCard extends StatelessWidget {
  final VelocityWorkoutCardData data;
  final double width;

  const VelocityWorkoutCard({
    super.key,
    required this.data,
    this.width = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Background subtle gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFAFCF8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Athlete cutout image on the right/bottom
            Positioned(
              right: -10,
              top: 50,
              bottom: 60,
              width: 175,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.white, Colors.white],
                    stops: [0.0, 0.25, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  data.imageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.velocitySurfaceMuted,
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 48,
                          color: AppTheme.velocityTextMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Content Overlay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Stylized Highlighted Title
                  Text(
                    data.firstLine,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.velocityTextPrimary,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  for (final phrase in data.highlightedPhrases) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: data.highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        phrase,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.velocityDark,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                  if (data.lastLine.isNotEmpty) ...[
                    Text(
                      data.lastLine,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.velocityTextPrimary,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // 2. Target Bullet Points
                  for (final bullet in data.bulletPoints) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          _buildTargetIcon(data.highlightColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bullet,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2B3626),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 3. Start Workout Pill Button
                  InkWell(
                    onTap: data.onStart,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            data.highlightColor.withValues(alpha: 0.28),
                            data.highlightColor.withValues(alpha: 0.45),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: data.highlightColor.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Start Workout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.velocityDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetIcon(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6B8A2B), width: 2),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF47601B),
          ),
        ),
      ),
    );
  }
}
