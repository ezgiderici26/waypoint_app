import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waypoint_app/core/services/notification_service.dart';
import 'package:waypoint_app/features/location_map/domain/entities/location_data.dart';
import 'package:waypoint_app/features/location_map/presentation/providers/location_providers.dart';
import 'package:waypoint_app/features/location_map/presentation/providers/geofence_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Unit Tests', () {
    test(
      'NotificationService records sent notifications into history',
      () async {
        final notifService = NotificationService();
        notifService.clearHistory();

        expect(notifService.history.isEmpty, isTrue);

        await notifService.showGeofenceEnterNotification(
          'Kadıköy Meydan',
          200.0,
        );
        expect(notifService.history.length, equals(1));
        expect(notifService.history.first.type, equals('ENTER'));
        expect(notifService.history.first.title.contains('Girdiniz'), isTrue);

        await notifService.showGeofenceExitNotification(
          'Kadıköy Meydan',
          350.0,
        );
        expect(notifService.history.length, equals(2));
        expect(notifService.history.first.type, equals('EXIT'));
        expect(notifService.history.first.title.contains('Çıktınız'), isTrue);

        await notifService.showTestNotification();
        expect(notifService.history.length, equals(3));
        expect(notifService.history.first.type, equals('TEST'));

        notifService.clearHistory();
        expect(notifService.history.isEmpty, isTrue);
      },
    );
  });

  group('Geofence Transition & Background Tracking Tests', () {
    test(
      'Detects entering and exiting geofence transitions and triggers notifications',
      () async {
        final notifService = NotificationService();
        notifService.clearHistory();

        final locationController = StreamController<LocationData>();

        final container = ProviderContainer(
          overrides: [
            locationStreamProvider.overrideWith(
              (ref) => locationController.stream,
            ),
            targetLocationProvider.overrideWith(
              (ref) => const TargetLocation(
                name: 'Kadıköy Meydan',
                latitude: 40.9905,
                longitude: 29.0255,
                radius: 200.0,
              ),
            ),
          ],
        );

        // Keep geofence provider active
        container.listen(geofenceProvider, (prev, next) {});

        // 1. Initial status
        expect(
          container.read(geofenceProvider).status,
          equals(GeofenceStatus.unknown),
        );

        // 2. User location OUTSIDE geofence (~2.5 km away in Üsküdar: 41.0250, 29.0150)
        final now = DateTime.now();
        locationController.add(
          LocationData(
            latitude: 41.0250,
            longitude: 29.0150,
            speed: 5.0,
            accuracy: 3.0,
            bearing: 0.0,
            timestamp: now,
            isMocked: false,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 15));

        final stateOutside = container.read(geofenceProvider);
        expect(stateOutside.status, equals(GeofenceStatus.outside));
        expect(stateOutside.isInside, isFalse);
        expect(stateOutside.currentDistance! > 200.0, isTrue);

        // 3. User location MOVES INSIDE geofence (Kadıköy Meydan center: 40.9905, 29.0255)
        locationController.add(
          LocationData(
            latitude: 40.9905,
            longitude: 29.0255,
            speed: 1.0,
            accuracy: 2.0,
            bearing: 0.0,
            timestamp: now.add(const Duration(seconds: 5)),
            isMocked: false,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 15));

        final stateInside = container.read(geofenceProvider);
        expect(stateInside.status, equals(GeofenceStatus.inside));
        expect(stateInside.isInside, isTrue);
        expect(stateInside.lastEvent?.type, equals('ENTER'));
        expect(stateInside.eventsHistory.length, equals(1));
        expect(notifService.history.any((n) => n.type == 'ENTER'), isTrue);

        // 4. User STAYS INSIDE (no duplicate enter notification)
        final notifCountBefore = notifService.history.length;
        locationController.add(
          LocationData(
            latitude: 40.9906,
            longitude: 29.0256,
            speed: 1.2,
            accuracy: 2.0,
            bearing: 0.0,
            timestamp: now.add(const Duration(seconds: 10)),
            isMocked: false,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 15));

        expect(
          container.read(geofenceProvider).status,
          equals(GeofenceStatus.inside),
        );
        expect(
          notifService.history.length,
          equals(notifCountBefore),
        ); // No duplicate notification

        // 5. User EXITS geofence (moving 500m away to 40.9960, 29.0255)
        locationController.add(
          LocationData(
            latitude: 40.9960,
            longitude: 29.0255,
            speed: 4.0,
            accuracy: 3.0,
            bearing: 0.0,
            timestamp: now.add(const Duration(seconds: 15)),
            isMocked: false,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 15));

        final stateExited = container.read(geofenceProvider);
        expect(stateExited.status, equals(GeofenceStatus.outside));
        expect(stateExited.isInside, isFalse);
        expect(stateExited.lastEvent?.type, equals('EXIT'));
        expect(stateExited.eventsHistory.length, equals(2));
        expect(notifService.history.first.type, equals('EXIT'));

        await locationController.close();
        container.dispose();
      },
    );

    test(
      'Geofence manual simulation triggers entry and exit properly',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(geofenceProvider.notifier);

        // Simulate Enter
        await notifier.simulateGeofenceEnter();
        var state = container.read(geofenceProvider);
        expect(state.status, equals(GeofenceStatus.inside));
        expect(state.lastEvent?.type, equals('ENTER'));

        // Simulate Exit
        await notifier.simulateGeofenceExit();
        state = container.read(geofenceProvider);
        expect(state.status, equals(GeofenceStatus.outside));
        expect(state.lastEvent?.type, equals('EXIT'));

        // Clear events
        notifier.clearEvents();
        state = container.read(geofenceProvider);
        expect(state.eventsHistory.isEmpty, isTrue);

        container.dispose();
      },
    );
  });
}
