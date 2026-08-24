import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waypoint_app/features/location_map/domain/entities/location_data.dart';
import 'package:waypoint_app/features/location_map/presentation/providers/antispoofing_providers.dart';
import 'package:waypoint_app/features/location_map/presentation/providers/location_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Antispoofing and Risk Scoring Logic Tests', () {
    test('K1 OS Mock Detection & K4 Speed Anomaly Tests', () async {
      final controller = StreamController<LocationData>();
      
      final container = ProviderContainer(
        overrides: [
          // Override the location stream with our custom test stream
          locationStreamProvider.overrideWith((ref) => controller.stream),
        ],
      );

      // Listen to the provider to keep it active
      container.listen(antispoofingProvider, (prev, next) {});

      // 1. Initial State check
      expect(container.read(antispoofingProvider).riskScore, equals(0));

      // 2. Emit normal location
      final now = DateTime.now();
      controller.add(LocationData(
        latitude: 41.0082,
        longitude: 28.9784,
        speed: 10.0,
        accuracy: 3.0,
        bearing: 0.0,
        timestamp: now,
        isMocked: false,
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(container.read(antispoofingProvider).riskScore, equals(0));
      expect(container.read(antispoofingProvider).isOsMocked, isFalse);

      // 3. Emit OS Mocked location (K1)
      controller.add(LocationData(
        latitude: 41.0082,
        longitude: 28.9784,
        speed: 10.0,
        accuracy: 3.0,
        bearing: 0.0,
        timestamp: now.add(const Duration(seconds: 2)),
        isMocked: true, // K1 Triggered!
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      // K1 adds 75 points in our new weighted model
      expect(container.read(antispoofingProvider).riskScore, equals(75));
      expect(container.read(antispoofingProvider).isOsMocked, isTrue);

      // 4. Emit location with impossible speed / teleportation (K4)
      // Moving from Istanbul (41.0082, 28.9784) to Ankara (39.9334, 32.8597) in 2 seconds (~350 km)
      final controller2 = StreamController<LocationData>();
      final container2 = ProviderContainer(
        overrides: [
          locationStreamProvider.overrideWith((ref) => controller2.stream),
        ],
      );
      container2.listen(antispoofingProvider, (prev, next) {});

      controller2.add(LocationData(
        latitude: 41.0082,
        longitude: 28.9784,
        speed: 10.0,
        accuracy: 3.0,
        bearing: 0.0,
        timestamp: now,
        isMocked: false,
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      controller2.add(LocationData(
        latitude: 39.9334,
        longitude: 32.8597,
        speed: 10.0,
        accuracy: 3.0,
        bearing: 0.0,
        timestamp: now.add(const Duration(seconds: 2)),
        isMocked: false,
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(container2.read(antispoofingProvider).isSpeedImpossible, isTrue);
      // K4 adds 70 points in our new weighted model
      expect(container2.read(antispoofingProvider).riskScore, equals(70));

      await controller.close();
      await controller2.close();
      container.dispose();
      container2.dispose();
    });
  });
}
