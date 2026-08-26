import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waypoint_app/main.dart';

void main() {
  testWidgets('Waypoint App Smoke Test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: WaypointApp()));

    // Verify that the app brand is displayed on the welcome screen.
    expect(find.text('WAYPOINT'), findsOneWidget);
  });
}
