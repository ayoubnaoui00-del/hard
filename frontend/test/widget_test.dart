import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/main.dart';

void main() {
  testWidgets('App renders first screen on launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GymTrackApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify that the first screen renders only the HARD barbell logo
    final logoFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/images/hard_logo.png',
    );
    expect(logoFinder, findsOneWidget);

    // Tap screen to advance to login
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    // Verify login screen renders
    expect(find.text('Log In'), findsOneWidget);
  });
}
