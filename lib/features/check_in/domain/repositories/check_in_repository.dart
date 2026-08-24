import '../entities/check_in_log.dart';

abstract class CheckInRepository {
  Future<List<CheckInLog>> getCheckInHistory();
  Future<void> saveCheckIn(CheckInLog log);
  Future<void> syncCheckIns();
}
