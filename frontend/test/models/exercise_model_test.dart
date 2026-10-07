import 'package:flutter_test/flutter_test.dart';
import 'package:gymtrack/models/exercise_model.dart';
import 'package:gymtrack/config/constants.dart';

void main() {
  group('ExerciseModel & Media URL Tests', () {
    test('AppConstants.resolveMediaUrl correctly formats paths', () {
      final host = AppConstants.baseHostUrl;
      expect(
        AppConstants.resolveMediaUrl('/media/exercises/images/0001.jpg'),
        '$host/media/exercises/images/0001.jpg',
      );
      expect(
        AppConstants.resolveMediaUrl('media/exercises/videos/0001.gif'),
        '$host/media/exercises/videos/0001.gif',
      );
      expect(
        AppConstants.resolveMediaUrl('https://cdn.example.com/demo.gif'),
        'https://cdn.example.com/demo.gif',
      );
      expect(AppConstants.resolveMediaUrl(null), isNull);
      expect(AppConstants.resolveMediaUrl(''), isNull);
    });

    test('ExerciseModel.fromJson extracts imageUrl and videoUrl from backend response', () {
      final json = {
        'id': 'd2a00840-778b-4413-8a9d-845fe0503b27',
        'name': '3/4 sit-up',
        'muscleGroup': 'Core',
        'instructions': 'Lie flat on your back...',
        'formTips': 'Target: abs',
        'imageUrl': '/media/exercises/images/0001-2gPfomN.jpg',
        'videoUrl': '/media/exercises/videos/0001-2gPfomN.gif',
        'gifUrl': '/media/exercises/videos/0001-2gPfomN.gif',
        'alternatives': {
          'originalId': '0001',
          'category': 'waist',
          'bodyPart': 'waist',
          'target': 'abs',
          'equipment': 'body weight',
          'secondaryMuscles': ['hip flexors', 'lower back'],
          'imageUrl': 'images/0001-2gPfomN.jpg',
          'gifUrl': 'videos/0001-2gPfomN.gif',
        },
      };

      final exercise = ExerciseModel.fromJson(json);

      expect(exercise.name, '3/4 sit-up');
      expect(exercise.muscleGroup, 'Core');
      expect(exercise.category, 'waist');
      expect(exercise.equipment, 'body weight');
      expect(exercise.imageUrl, isNotNull);
      expect(exercise.imageUrl, contains('/media/exercises/images/0001-2gPfomN.jpg'));
      expect(exercise.videoUrl, isNotNull);
      expect(exercise.videoUrl, contains('/media/exercises/videos/0001-2gPfomN.gif'));
      expect(exercise.gifUrl, exercise.videoUrl);
      expect(exercise.alternativeNames, ['hip flexors', 'lower back']);
    });

    test('ExerciseModel.fromJson falls back to alternatives object when top-level URLs missing', () {
      final json = {
        'id': 'abc-123',
        'name': 'Bench Press',
        'muscleGroup': 'Chest',
        'alternatives': {
          'category': 'Strength',
          'equipment': 'Barbell',
          'imageUrl': 'images/bench.jpg',
          'gifUrl': 'videos/bench.gif',
        },
      };

      final exercise = ExerciseModel.fromJson(json);

      expect(exercise.imageUrl, contains('images/bench.jpg'));
      expect(exercise.videoUrl, contains('videos/bench.gif'));
      expect(exercise.gifUrl, contains('videos/bench.gif'));
    });
  });
}
