class CheckInLog {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final int riskScore;
  final DateTime timestamp;
  final bool isSynced;

  const CheckInLog({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.riskScore,
    required this.timestamp,
    required this.isSynced,
  });
}
