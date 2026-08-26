import 'dart:math';
import '../../../check_in/domain/entities/check_in_record.dart';

class HeatmapCluster {
  final String id;
  final double latitude;
  final double longitude;
  final List<CheckInRecord> records;
  final String primaryTargetName;

  const HeatmapCluster({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.records,
    required this.primaryTargetName,
  });

  int get count => records.length;

  double get averageRiskScore {
    if (records.isEmpty) return 0.0;
    final total = records.fold<int>(0, (sum, r) => sum + r.riskScore);
    return total / records.length;
  }

  int get highestRiskScore {
    if (records.isEmpty) return 0;
    return records.map((r) => r.riskScore).reduce(max);
  }

  int get safeCount =>
      records.where((r) => !r.isBlocked && r.riskScore < 35).length;
  int get suspiciousCount =>
      records.where((r) => r.riskScore >= 35 && r.riskScore < 70).length;
  int get blockedCount =>
      records.where((r) => r.isBlocked || r.riskScore >= 70).length;

  bool get hasHighRisk => blockedCount > 0 || highestRiskScore >= 70;

  /// Returns calculated density level between 1.0 and 5.0
  double get densityLevel {
    if (count <= 1) return 1.0;
    if (count <= 3) return 2.0;
    if (count <= 7) return 3.5;
    return 5.0;
  }
}
