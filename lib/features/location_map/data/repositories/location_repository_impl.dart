import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl();

  @override
  Stream<LocationData> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Get updates every meter
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (Position position) => _mapPositionToLocationData(position),
    );
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return _mapPositionToLocationData(position);
  }

  @override
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    // Haversine distance formula implementation
    const double r = 6371000; // Earth radius in meters
    final double dLat = _toRadians(endLat - startLat);
    final double dLng = _toRadians(endLng - startLng);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLat)) * cos(_toRadians(endLat)) * 
        sin(dLng / 2) * sin(dLng / 2);
        
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
