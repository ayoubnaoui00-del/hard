import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/main.dart';

void main() {
  testWidgets('App renders LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GymTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the login screen renders VELOCITY title
    expect(find.text('VELOCITY'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
