import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waypoint_app/features/check_in/domain/entities/check_in_record.dart';
import 'package:waypoint_app/features/check_in/presentation/providers/check_in_providers.dart';
import 'package:waypoint_app/features/heatmap/domain/entities/heatmap_cluster.dart';
import 'package:waypoint_app/features/heatmap/presentation/providers/heatmap_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeatmapCluster Entity Tests', () {
    test(
      'Calculates count, average risk, safe and blocked counts accurately',
      () {
        final records = [
          CheckInRecord(
            id: '1',
            timestamp: DateTime.now().toIso8601String(),
            latitude: 40.9905,
            longitude: 29.0255,
            accuracy: 4.0,
            riskScore: 10,
            deviceStatus: 'Normal',
            targetName: 'Kadıköy',
            isSynced: true,
            isBlocked: false,
          ),
          CheckInRecord(
            id: '2',
            timestamp: DateTime.now().toIso8601String(),
            latitude: 40.9906,
            longitude: 29.0256,
            accuracy: 3.5,
            riskScore: 30,
            deviceStatus: 'Normal',
            targetName: 'Kadıköy',
            isSynced: true,
            isBlocked: false,
          ),
          CheckInRecord(
            id: '3',
            timestamp: DateTime.now().toIso8601String(),
            latitude: 40.9907,
            longitude: 29.0254,
            accuracy: 5.0,
            riskScore: 80,
            deviceStatus: 'Rooted: true',
            targetName: 'Kadıköy',
            isSynced: false,
            isBlocked: true,
          ),
        ];

        final cluster = HeatmapCluster(
          id: 'cluster-kadikoy',
          latitude: 40.9906,
          longitude: 29.0255,
          records: records,
          primaryTargetName: 'Kadıköy',
        );

        expect(cluster.count, equals(3));
        expect(cluster.averageRiskScore, closeTo(40.0, 0.01));
        expect(cluster.highestRiskScore, equals(80));
        expect(cluster.safeCount, equals(2));
        expect(cluster.blockedCount, equals(1));
        expect(cluster.hasHighRisk, isTrue);
        expect(cluster.densityLevel, equals(2.0));
      },
    );
  });

  group('Heatmap Providers Logic & Filtering Tests', () {
    final now = DateTime.now();
    final sampleRecords = [
      // Kadıköy Safe Cluster (2 records)
      CheckInRecord(
        id: 'kd-1',
        timestamp: now.toIso8601String(),
        latitude: 40.9905,
        longitude: 29.0255,
        accuracy: 4.0,
        riskScore: 15,
        deviceStatus: 'OK',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'kd-2',
        timestamp: now.toIso8601String(),
        latitude: 40.9906,
        longitude: 29.0256,
        accuracy: 3.5,
        riskScore: 20,
        deviceStatus: 'OK',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: false,
      ),

      // Taksim Threat Cluster (1 record, 85 risk, blocked)
      CheckInRecord(
        id: 'tks-1',
        timestamp: now
            .subtract(const Duration(hours: 48))
            .toIso8601String(), // 2 days ago
        latitude: 41.0370,
        longitude: 28.9850,
        accuracy: 4.0,
        riskScore: 85,
        deviceStatus: 'Mock GPS',
        targetName: 'Taksim Meydanı',
        isSynced: true,
        isBlocked: true,
      ),
    ];

    test(
      'Clustering groups geographically proximate records and separates distant ones',
      () {
        final container = ProviderContainer(
          overrides: [
            checkInHistoryProvider.overrideWith(
              (ref) => MockCheckInHistoryNotifier(sampleRecords),
            ),
          ],
        );

        final clusters = container.read(heatmapClustersProvider);
        expect(clusters.length, equals(2)); // Kadıköy and Taksim

        final kadikoyCluster = clusters.firstWhere(
          (c) => c.primaryTargetName.contains('Kadıköy'),
        );
        expect(kadikoyCluster.count, equals(2));
        expect(kadikoyCluster.safeCount, equals(2));

        final taksimCluster = clusters.firstWhere(
          (c) => c.primaryTargetName.contains('Taksim'),
        );
        expect(taksimCluster.count, equals(1));
        expect(taksimCluster.hasHighRisk, isTrue);

        container.dispose();
      },
    );

    test('Risk filtering returns only safe or only risky records', () {
      final container = ProviderContainer(
        overrides: [
          checkInHistoryProvider.overrideWith(
            (ref) => MockCheckInHistoryNotifier(sampleRecords),
          ),
        ],
      );

      final notifier = container.read(heatmapNotifierProvider.notifier);

      // Safe only
      notifier.setRiskFilter(RiskFilter.safeOnly);
      var filtered = container.read(filteredHeatmapRecordsProvider);
      expect(filtered.length, equals(2));
      expect(filtered.every((r) => !r.isBlocked && r.riskScore < 35), isTrue);

      // Risky only
      notifier.setRiskFilter(RiskFilter.riskyOnly);
      filtered = container.read(filteredHeatmapRecordsProvider);
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('tks-1'));

      container.dispose();
    });

    test('Time filtering filters out older records', () {
      final container = ProviderContainer(
        overrides: [
          checkInHistoryProvider.overrideWith(
            (ref) => MockCheckInHistoryNotifier(sampleRecords),
          ),
        ],
      );

      final notifier = container.read(heatmapNotifierProvider.notifier);

      // Last 24 hours should exclude the 48-hour old Taksim record
      notifier.setTimeFilter(TimeFilter.last24Hours);
      final filtered = container.read(filteredHeatmapRecordsProvider);
      expect(filtered.length, equals(2));
      expect(filtered.any((r) => r.id == 'tks-1'), isFalse);

      container.dispose();
    });

    test('Heatmap stats computes correct KPI summary values', () {
      final container = ProviderContainer(
        overrides: [
          checkInHistoryProvider.overrideWith(
            (ref) => MockCheckInHistoryNotifier(sampleRecords),
          ),
        ],
      );

      final stats = container.read(heatmapStatsProvider);
      expect(stats.totalRecords, equals(3));
      expect(stats.safeRecords, equals(2));
      expect(stats.riskyOrBlockedRecords, equals(1));
      expect(stats.safePercentage, closeTo(66.66, 0.1));
      expect(stats.averageRiskScore, closeTo(40.0, 0.1));
      expect(stats.topHotspotName, equals('Kadıköy Meydan'));
      expect(stats.topHotspotCount, equals(2));
      expect(stats.vpnOrMockDetections, equals(1));

      container.dispose();
    });

    test(
      'Google Maps circles provider produces multi-layer gradient circles in density & risk modes',
      () {
        final container = ProviderContainer(
          overrides: [
            checkInHistoryProvider.overrideWith(
              (ref) => MockCheckInHistoryNotifier(sampleRecords),
            ),
          ],
        );

        final notifier = container.read(heatmapNotifierProvider.notifier);

        // Density mode circles (4 concentric layers per cluster -> 2 clusters = 8 circles)
        notifier.setMode(HeatmapMode.density);
        var circles = container.read(heatmapCirclesProvider);
        expect(circles.length, equals(8));

        // Risk mode circles (3 concentric layers per cluster -> 2 clusters = 6 circles)
        notifier.setMode(HeatmapMode.risk);
        circles = container.read(heatmapCirclesProvider);
        expect(circles.length, equals(6));

        container.dispose();
      },
    );
  });
}

class MockCheckInHistoryNotifier extends StateNotifier<List<CheckInRecord>>
    implements CheckInHistoryNotifier {
  MockCheckInHistoryNotifier(super.initialState);

  @override
  Future<void> addBulkRecords(List<CheckInRecord> records) async {
    state = [...state, ...records];
  }

  @override
  Future<void> clearAllRecords() async {
    state = [];
  }

  @override
  Future<void> addCheckInRecord({
    required double latitude,
    required double longitude,
    required double accuracy,
    required int riskScore,
    required String deviceStatus,
    required String targetName,
    required bool isBlocked,
  }) async {}

  @override
  Future<bool> syncPendingRecords() async => true;
}
