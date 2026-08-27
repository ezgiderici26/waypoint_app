import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl();

  @override
  Stream<LocationData> getLocationStream() async* {
    // 1. Immediately yield last known or initial current position so UI is instant on physical devices
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        yield _mapPositionToLocationData(lastKnown);
      }
    } catch (_) {}

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );
      yield _mapPositionToLocationData(current);
    } catch (_) {}

    // 2. Stream subsequent real-time updates safely
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Get updates every meter
      );

      yield* Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).map((Position position) => _mapPositionToLocationData(position))
      .handleError((error) {
        // Prevent stream errors from crashing Riverpod / app
      });
    } catch (_) {}
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
      return _mapPositionToLocationData(position);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return _mapPositionToLocationData(last);
        }
      } catch (_) {}

      // Fallback default coordinates (34 İstanbul)
      return LocationData(
        latitude: 41.0082,
        longitude: 28.9784,
        speed: 0,
        accuracy: 10,
        bearing: 0,
        timestamp: DateTime.now(),
        isMocked: false,
      );
    }
  }

  @override
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    // Haversine distance formula implementation
    const double r = 6371000; // Earth radius in meters
    final double dLat = _toRadians(endLat - startLat);
    final double dLng = _toRadians(endLng - startLng);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLat)) *
            cos(_toRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  LocationData _mapPositionToLocationData(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
      bearing: position.heading,
      timestamp: position.timestamp,
      isMocked: position.isMocked,
    );
  }
}
