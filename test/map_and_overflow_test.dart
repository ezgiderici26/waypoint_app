import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:waypoint_app/core/constants/turkey_provinces.dart';
import 'package:waypoint_app/features/location_map/domain/entities/location_data.dart';
import 'package:waypoint_app/features/location_map/presentation/providers/location_providers.dart';
import 'package:waypoint_app/features/location_map/presentation/widgets/open_street_map_view.dart';
import 'package:waypoint_app/features/location_map/presentation/screens/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Map & Layout Overflow Regression Tests', () {
    testWidgets('OpenStreetMapWidget renders safely with extreme risk scores and long city names', (tester) async {
      // Set small emulator screen size (360x640)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mapController = MapController();
      final userLocation = LocationData(
        latitude: 41.0082,
        longitude: 28.9784,
        speed: 12.5,
        accuracy: 15.0,
        bearing: 45.0,
        timestamp: DateTime.now(),
        isMocked: false,
      );

      final target = const TargetLocation(
        name: "Afyonkarahisar Zafer Meydanı ve Valilik Binası Kontrol Noktası",
        latitude: 38.7569,
        longitude: 30.5387,
        radius: 250.0,
      );

      final province = TurkeyProvinces.getByPlateCode(3) ?? TurkeyProvinces.all.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenStreetMapWidget(
              userLocation: userLocation,
              targetLocation: target,
              selectedProvince: province,
              riskScore: 95, // Extreme Spoofed Red
              isInsideGeofence: false,
              distanceToTarget: 1450.0,
              mapController: mapController,
              tileStyle: MapTileStyle.darkCyberpunk,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect that OpenStreetMapWidget rendered without throwing layout/overflow exceptions
      expect(find.byType(OpenStreetMapWidget), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining("SİZ (95/100)"), findsOneWidget);
    });

    testWidgets('WelcomeScreen renders on small screens without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480); // Ultra small screen
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text("WAYPOINT"), findsOneWidget);
    });
  });
}
