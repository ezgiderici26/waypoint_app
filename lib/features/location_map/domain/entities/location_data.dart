class LocationData {
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final double bearing;
  final DateTime timestamp;
  final bool isMocked;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.bearing,
    required this.timestamp,
    required this.isMocked,
  });
}
