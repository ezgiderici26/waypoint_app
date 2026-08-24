import '../../domain/entities/check_in_log.dart';
import '../../domain/repositories/check_in_repository.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  final List<CheckInLog> _mockLogs = [
    CheckInLog(
      id: "1",
      locationName: "Kadıköy Meydan",
      latitude: 41.0082,
      longitude: 28.9784,
      riskScore: 12,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isSynced: true,
    ),
    CheckInLog(
      id: "2",
      locationName: "Beşiktaş Sahil",
      latitude: 41.0428,
      longitude: 29.0075,
      riskScore: 45,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isSynced: true,
    ),
    CheckInLog(
      id: "3",
      locationName: "Taksim Metro",
      latitude: 41.0370,
      longitude: 28.9850,
      riskScore: 85,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isSynced: false,
    ),
  ];

  CheckInRepositoryImpl();

  @override
  Future<List<CheckInLog>> getCheckInHistory() async {
    // Simulate minor delay
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_mockLogs);
  }

  @override
  Future<void> saveCheckIn(CheckInLog log) async {
    _mockLogs.insert(0, log);
  }

  @override
  Future<void> syncCheckIns() async {
    await Future.delayed(const Duration(seconds: 1));
    for (int i = 0; i < _mockLogs.length; i++) {
      if (!_mockLogs[i].isSynced) {
        _mockLogs[i] = CheckInLog(
          id: _mockLogs[i].id,
          locationName: _mockLogs[i].locationName,
          latitude: _mockLogs[i].latitude,
          longitude: _mockLogs[i].longitude,
          riskScore: _mockLogs[i].riskScore,
          timestamp: _mockLogs[i].timestamp,
          isSynced: true,
        );
      }
    }
  }
}
