import 'package:flutter/material.dart';

/// Muscle group definitions with assigned neon theme colors and anatomy data
enum MuscleGroupType {
  chest(
    name: 'Chest',
    color: Color(0xFFFF5252),
    isFront: true,
    icon: Icons.fitness_center_rounded,
    description: 'Pectoralis Major & Minor',
  ),
  back(
    name: 'Back',
    color: Color(0xFF2979FF),
    isFront: false,
    icon: Icons.shield_outlined,
    description: 'Latissimus Dorsi, Traps & Rhomboids',
  ),
  shoulders(
    name: 'Shoulders',
    color: Color(0xFFFF9100),
    isFront: true,
    icon: Icons.hardware_rounded,
    description: 'Anterior, Lateral & Posterior Deltoids',
  ),
  arms(
    name: 'Arms',
    color: Color(0xFFB388FF),
    isFront: true,
    icon: Icons.sports_martial_arts_rounded,
    description: 'Biceps, Triceps & Forearms',
  ),
  legs(
    name: 'Legs',
    color: Color(0xFF00E676),
    isFront: true,
    icon: Icons.directions_run_rounded,
    description: 'Quadriceps, Hamstrings, Glutes & Calves',
  ),
  core(
    name: 'Core',
    color: Color(0xFF00E5FF),
    isFront: true,
    icon: Icons.adjust_rounded,
    description: 'Rectus Abdominis & Obliques',
  );

  final String name;
  final Color color;
  final bool isFront;
  final IconData icon;
  final String description;

  const MuscleGroupType({
    required this.name,
    required this.color,
    required this.isFront,
    required this.icon,
    required this.description,
  });

  static MuscleGroupType fromString(String name) {
    return MuscleGroupType.values.firstWhere(
      (m) => m.name.toLowerCase() == name.toLowerCase(),
      orElse: () => MuscleGroupType.chest,
    );
  }
}
