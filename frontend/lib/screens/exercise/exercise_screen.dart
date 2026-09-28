import 'package:flutter/material.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises, muscle groups...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.accessibility_new_rounded),
                  tooltip: '3D Muscle Picker',
                  onPressed: () {},
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildExerciseItem(
                  context,
                  title: 'Bench Press (Barbell)',
                  muscle: 'Chest',
                  category: 'Barbell',
                ),
                _buildExerciseItem(
                  context,
                  title: 'Squat (Barbell)',
                  muscle: 'Quadriceps',
                  category: 'Barbell',
                ),
                _buildExerciseItem(
                  context,
                  title: 'Deadlift (Barbell)',
                  muscle: 'Back / Hamstrings',
                  category: 'Barbell',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(
    BuildContext context, {
    required String title,
    required String muscle,
    required String category,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.fitness_center_rounded, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$muscle • $category', style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
