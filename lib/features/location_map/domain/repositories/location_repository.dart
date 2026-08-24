import '../entities/location_data.dart';

abstract class LocationRepository {
  Stream<LocationData> getLocationStream();
  Future<LocationData> getCurrentLocation();
  double calculateDistance(double startLat, double startLng, double endLat, double endLng);
}
