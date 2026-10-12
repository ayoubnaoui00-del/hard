import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/main.dart';

void main() {
  group('Minimalist First Screen & Splash Navigation Tests', () {
    testWidgets('Renders empty screen with only the centered HARD logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GymTrackApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Barbell Logo Image is present in the center
      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/images/hard_logo.png',
      );
      expect(imageFinder, findsOneWidget);

      // Verify no buttons or clutter are on this initial screen
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('Tapping the screen advances to LoginView', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GymTrackApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap on the screen to skip/proceed
      final gestureFinder = find.byType(GestureDetector);
      expect(gestureFinder, findsWidgets);
      await tester.tap(gestureFinder.first);
      await tester.pumpAndSettle();

      // Now on LoginView
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
    });

    testWidgets('Can navigate from LoginView to RegisterView and back', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GymTrackApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap screen to proceed to login
      final gestureFinder = find.byType(GestureDetector);
      await tester.tap(gestureFinder.first);
      await tester.pumpAndSettle();

      // Tap 'Sign Up'
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // On RegisterView
      expect(find.text('Join HARD ⚡'), findsOneWidget);

      // Tap back button returns to LoginView
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text("Don't have an account?"), findsOneWidget);
    });
  });
}
