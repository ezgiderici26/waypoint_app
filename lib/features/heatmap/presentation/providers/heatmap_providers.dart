import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../check_in/domain/entities/check_in_record.dart';
import '../../../check_in/presentation/providers/check_in_providers.dart';
import '../../domain/entities/heatmap_cluster.dart';
import '../../../../core/theme/app_theme.dart';

enum HeatmapMode {
  density, // Yoğunluk Odaklı (Density Heatmap)
  risk, // Tehdit ve Güvenlik Riski Odaklı (Risk/Spoofing Heatmap)
  points, // Noktasal / Detaylı Pin Görünümü
}

enum RiskFilter {
  all, // Tümü
  safeOnly, // Sadece Güvenli (< 35)
  riskyOnly, // Sadece Riskli / Engellenmiş (>= 35)
}

enum TimeFilter {
  allTime, // Tüm Zamanlar
  last24Hours, // Son 24 Saat
  last7Days, // Son 7 Gün
}

class HeatmapState {
  final HeatmapMode mode;
  final RiskFilter riskFilter;
  final TimeFilter timeFilter;
  final double radiusMultiplier;
  final HeatmapCluster? selectedCluster;
  final CheckInRecord? selectedRecord;

  const HeatmapState({
    this.mode = HeatmapMode.density,
    this.riskFilter = RiskFilter.all,
    this.timeFilter = TimeFilter.allTime,
    this.radiusMultiplier = 1.0,
    this.selectedCluster,
    this.selectedRecord,
  });

  HeatmapState copyWith({
    HeatmapMode? mode,
    RiskFilter? riskFilter,
    TimeFilter? timeFilter,
    double? radiusMultiplier,
    HeatmapCluster? selectedCluster,
    bool clearSelectedCluster = false,
    CheckInRecord? selectedRecord,
    bool clearSelectedRecord = false,
  }) {
    return HeatmapState(
      mode: mode ?? this.mode,
      riskFilter: riskFilter ?? this.riskFilter,
      timeFilter: timeFilter ?? this.timeFilter,
      radiusMultiplier: radiusMultiplier ?? this.radiusMultiplier,
      selectedCluster: clearSelectedCluster
          ? null
          : (selectedCluster ?? this.selectedCluster),
      selectedRecord: clearSelectedRecord
          ? null
          : (selectedRecord ?? this.selectedRecord),
    );
  }
}

class HeatmapNotifier extends StateNotifier<HeatmapState> {
  HeatmapNotifier() : super(const HeatmapState());

  void setMode(HeatmapMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setRiskFilter(RiskFilter filter) {
    state = state.copyWith(riskFilter: filter);
  }

  void setTimeFilter(TimeFilter filter) {
    state = state.copyWith(timeFilter: filter);
  }

  void setRadiusMultiplier(double multiplier) {
    state = state.copyWith(radiusMultiplier: multiplier.clamp(0.4, 3.0));
  }

  void selectCluster(HeatmapCluster? cluster) {
    state = state.copyWith(
      selectedCluster: cluster,
      clearSelectedCluster: cluster == null,
      clearSelectedRecord: true,
    );
  }

  void selectRecord(CheckInRecord? record) {
    state = state.copyWith(
      selectedRecord: record,
      clearSelectedRecord: record == null,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      clearSelectedCluster: true,
      clearSelectedRecord: true,
    );
  }

  /// Populates realistic demo clusters for admin testing across Istanbul hubs
  Future<void> seedHeatmapDemoData(WidgetRef ref) async {
    final now = DateTime.now();
    final List<CheckInRecord> demoRecords = [
      // 1. Kadıköy Meydan Hub (Yüksek Güvenli Yoğunluk)
      CheckInRecord(
        id: 'seed-kd-1',
        timestamp: now.subtract(const Duration(minutes: 15)).toIso8601String(),
        latitude: 40.9905,
        longitude: 29.0255,
        accuracy: 4.2,
        riskScore: 12,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-kd-2',
        timestamp: now.subtract(const Duration(minutes: 42)).toIso8601String(),
        latitude: 40.9907,
        longitude: 29.0258,
        accuracy: 3.8,
        riskScore: 18,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-kd-3',
        timestamp: now
            .subtract(const Duration(hours: 1, minutes: 10))
            .toIso8601String(),
        latitude: 40.9903,
        longitude: 29.0252,
        accuracy: 5.0,
        riskScore: 22,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-kd-4',
        timestamp: now.subtract(const Duration(hours: 2)).toIso8601String(),
        latitude: 40.9906,
        longitude: 29.0256,
        accuracy: 4.0,
        riskScore: 15,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-kd-5',
        timestamp: now.subtract(const Duration(hours: 3)).toIso8601String(),
        latitude: 40.9904,
        longitude: 29.0257,
        accuracy: 4.5,
        riskScore: 42,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: true',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: true,
      ),
      CheckInRecord(
        id: 'seed-kd-6',
        timestamp: now.subtract(const Duration(hours: 4)).toIso8601String(),
        latitude: 40.9908,
        longitude: 29.0254,
        accuracy: 3.2,
        riskScore: 10,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Kadıköy Meydan',
        isSynced: true,
        isBlocked: false,
      ),

      // 2. Beşiktaş Sahil & Çarşı Hub (Orta Güvenli Yoğunluk)
      CheckInRecord(
        id: 'seed-bsk-1',
        timestamp: now.subtract(const Duration(minutes: 30)).toIso8601String(),
        latitude: 41.0428,
        longitude: 29.0075,
        accuracy: 4.1,
        riskScore: 8,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Beşiktaş Sahil',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-bsk-2',
        timestamp: now
            .subtract(const Duration(hours: 1, minutes: 45))
            .toIso8601String(),
        latitude: 41.0430,
        longitude: 29.0078,
        accuracy: 3.9,
        riskScore: 14,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Beşiktaş Sahil',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-bsk-3',
        timestamp: now
            .subtract(const Duration(hours: 2, minutes: 20))
            .toIso8601String(),
        latitude: 41.0426,
        longitude: 29.0072,
        accuracy: 5.5,
        riskScore: 25,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Beşiktaş Sahil',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-bsk-4',
        timestamp: now.subtract(const Duration(hours: 5)).toIso8601String(),
        latitude: 41.0429,
        longitude: 29.0076,
        accuracy: 4.8,
        riskScore: 19,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Beşiktaş Sahil',
        isSynced: true,
        isBlocked: false,
      ),

      // 3. Taksim Meydanı & Gezi Hub (Tehdit / Sahtecilik Saldırı Bölgesi)
      CheckInRecord(
        id: 'seed-tks-1',
        timestamp: now.subtract(const Duration(minutes: 50)).toIso8601String(),
        latitude: 41.0370,
        longitude: 28.9850,
        accuracy: 3.5,
        riskScore: 85,
        deviceStatus: 'Rooted: false, Emulator: true, VPN: true (OS Mock Flag)',
        targetName: 'Taksim Meydanı',
        isSynced: true,
        isBlocked: true,
      ),
      CheckInRecord(
        id: 'seed-tks-2',
        timestamp: now
            .subtract(const Duration(hours: 1, minutes: 30))
            .toIso8601String(),
        latitude: 41.0372,
        longitude: 28.9853,
        accuracy: 4.0,
        riskScore: 90,
        deviceStatus:
            'Rooted: true, Emulator: false, VPN: false (Işınlanma/K4)',
        targetName: 'Taksim Meydanı',
        isSynced: true,
        isBlocked: true,
      ),
      CheckInRecord(
        id: 'seed-tks-3',
        timestamp: now
            .subtract(const Duration(hours: 3, minutes: 15))
            .toIso8601String(),
        latitude: 41.0368,
        longitude: 28.9848,
        accuracy: 6.0,
        riskScore: 78,
        deviceStatus:
            'Rooted: false, Emulator: false, VPN: true (Sensör Uyuşmazlığı)',
        targetName: 'Taksim Meydanı',
        isSynced: false,
        isBlocked: true,
      ),
      CheckInRecord(
        id: 'seed-tks-4',
        timestamp: now.subtract(const Duration(hours: 6)).toIso8601String(),
        latitude: 41.0371,
        longitude: 28.9851,
        accuracy: 4.2,
        riskScore: 20,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Taksim Meydanı',
        isSynced: true,
        isBlocked: false,
      ),

      // 4. Levent Finans & Plaza Hub (Orta Güvenli Yoğunluk)
      CheckInRecord(
        id: 'seed-lvt-1',
        timestamp: now.subtract(const Duration(hours: 1)).toIso8601String(),
        latitude: 41.0822,
        longitude: 29.0125,
        accuracy: 3.0,
        riskScore: 15,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Levent Plaza',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-lvt-2',
        timestamp: now
            .subtract(const Duration(hours: 2, minutes: 40))
            .toIso8601String(),
        latitude: 41.0825,
        longitude: 29.0128,
        accuracy: 4.5,
        riskScore: 12,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Levent Plaza',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-lvt-3',
        timestamp: now
            .subtract(const Duration(hours: 4, minutes: 50))
            .toIso8601String(),
        latitude: 41.0820,
        longitude: 29.0122,
        accuracy: 3.8,
        riskScore: 18,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Levent Plaza',
        isSynced: true,
        isBlocked: false,
      ),

      // 5. Maslak Teknoloji & İTÜ Hub (Karışık Tehdit & Güvenlik)
      CheckInRecord(
        id: 'seed-msl-1',
        timestamp: now.subtract(const Duration(minutes: 25)).toIso8601String(),
        latitude: 41.1060,
        longitude: 29.0240,
        accuracy: 4.0,
        riskScore: 16,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Maslak İTÜ',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-msl-2',
        timestamp: now
            .subtract(const Duration(hours: 2, minutes: 10))
            .toIso8601String(),
        latitude: 41.1063,
        longitude: 29.0244,
        accuracy: 3.5,
        riskScore: 75,
        deviceStatus: 'Rooted: false, Emulator: true, VPN: true',
        targetName: 'Maslak İTÜ',
        isSynced: true,
        isBlocked: true,
      ),

      // 6. Kadıköy Moda Sahil Hub
      CheckInRecord(
        id: 'seed-mda-1',
        timestamp: now
            .subtract(const Duration(hours: 1, minutes: 20))
            .toIso8601String(),
        latitude: 40.9840,
        longitude: 29.0280,
        accuracy: 4.1,
        riskScore: 10,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Moda Sahil',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-mda-2',
        timestamp: now
            .subtract(const Duration(hours: 3, minutes: 40))
            .toIso8601String(),
        latitude: 40.9842,
        longitude: 29.0283,
        accuracy: 5.2,
        riskScore: 14,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Moda Sahil',
        isSynced: true,
        isBlocked: false,
      ),

      // 7. Ankara Kızılay Hub (06)
      CheckInRecord(
        id: 'seed-ank-1',
        timestamp: now.subtract(const Duration(minutes: 45)).toIso8601String(),
        latitude: 39.9334,
        longitude: 32.8597,
        accuracy: 3.5,
        riskScore: 8,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Ankara Kızılay Meydanı',
        isSynced: true,
        isBlocked: false,
      ),
      CheckInRecord(
        id: 'seed-ank-2',
        timestamp: now.subtract(const Duration(hours: 2)).toIso8601String(),
        latitude: 39.9338,
        longitude: 32.8601,
        accuracy: 4.0,
        riskScore: 82,
        deviceStatus: 'Rooted: true, Emulator: true (K1+K2)',
        targetName: 'Ankara Kızılay Meydanı',
        isSynced: true,
        isBlocked: true,
      ),

      // 8. İzmir Konak Hub (35)
      CheckInRecord(
        id: 'seed-izm-1',
        timestamp: now
            .subtract(const Duration(hours: 1, minutes: 10))
            .toIso8601String(),
        latitude: 38.4192,
        longitude: 27.1287,
        accuracy: 2.8,
        riskScore: 12,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'İzmir Konak Saat Kulesi',
        isSynced: true,
        isBlocked: false,
      ),

      // 9. Bursa Heykel Hub (16)
      CheckInRecord(
        id: 'seed-brs-1',
        timestamp: now.subtract(const Duration(hours: 4)).toIso8601String(),
        latitude: 40.1885,
        longitude: 29.0610,
        accuracy: 3.2,
        riskScore: 18,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Bursa Kent Meydanı',
        isSynced: true,
        isBlocked: false,
      ),

      // 10. Antalya Muratpaşa Hub (07)
      CheckInRecord(
        id: 'seed-ant-1',
        timestamp: now.subtract(const Duration(hours: 5)).toIso8601String(),
        latitude: 36.8969,
        longitude: 30.7133,
        accuracy: 4.8,
        riskScore: 15,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Antalya Muratpaşa Meydanı',
        isSynced: true,
        isBlocked: false,
      ),

      // 11. Trabzon Meydan Hub (61)
      CheckInRecord(
        id: 'seed-tbz-1',
        timestamp: now.subtract(const Duration(hours: 3)).toIso8601String(),
        latitude: 41.0027,
        longitude: 39.7168,
        accuracy: 5.0,
        riskScore: 22,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Trabzon Meydan Parkı',
        isSynced: true,
        isBlocked: false,
      ),
    ];

    await ref.read(checkInHistoryProvider.notifier).addBulkRecords(demoRecords);
  }
}

final heatmapNotifierProvider =
    StateNotifierProvider<HeatmapNotifier, HeatmapState>((ref) {
      return HeatmapNotifier();
    });

/// Filters check-in records based on the selected Risk and Time filters
final filteredHeatmapRecordsProvider = Provider<List<CheckInRecord>>((ref) {
  final allRecords = ref.watch(checkInHistoryProvider);
  final state = ref.watch(heatmapNotifierProvider);

  return allRecords.where((record) {
    // 1. Risk Filtering
    if (state.riskFilter == RiskFilter.safeOnly &&
        (record.isBlocked || record.riskScore >= 35)) {
      return false;
    }
    if (state.riskFilter == RiskFilter.riskyOnly &&
        (!record.isBlocked && record.riskScore < 35)) {
      return false;
    }

    // 2. Time Filtering
    if (state.timeFilter != TimeFilter.allTime) {
      try {
        final recordTime = DateTime.parse(record.timestamp);
        final diff = DateTime.now().difference(recordTime);
        if (state.timeFilter == TimeFilter.last24Hours && diff.inHours > 24) {
          return false;
        }
        if (state.timeFilter == TimeFilter.last7Days && diff.inDays > 7) {
          return false;
        }
      } catch (_) {
        // In case of invalid timestamp format, keep record
      }
    }

    return true;
  }).toList();
});

/// Clusters filtered records that are geographically close (~120 meters)
final heatmapClustersProvider = Provider<List<HeatmapCluster>>((ref) {
  final records = ref.watch(filteredHeatmapRecordsProvider);
  if (records.isEmpty) return [];

  final List<HeatmapCluster> clusters = [];
  const double clusterThresholdMeters = 120.0;

  for (final record in records) {
    bool addedToCluster = false;

    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final distance = _calculateHaversineDistance(
        cluster.latitude,
        cluster.longitude,
        record.latitude,
        record.longitude,
      );

      if (distance <= clusterThresholdMeters) {
        final updatedRecords = List<CheckInRecord>.from(cluster.records)
          ..add(record);
        // Recalculate centroid average
        final newLat =
            updatedRecords.fold<double>(0.0, (s, r) => s + r.latitude) /
            updatedRecords.length;
        final newLng =
            updatedRecords.fold<double>(0.0, (s, r) => s + r.longitude) /
            updatedRecords.length;

        clusters[i] = HeatmapCluster(
          id: cluster.id,
          latitude: newLat,
          longitude: newLng,
          records: updatedRecords,
          primaryTargetName: cluster.primaryTargetName,
        );
        addedToCluster = true;
        break;
      }
    }

    if (!addedToCluster) {
      clusters.add(
        HeatmapCluster(
          id: 'cluster-${record.id}',
          latitude: record.latitude,
          longitude: record.longitude,
          records: [record],
          primaryTargetName: record.targetName,
        ),
      );
    }
  }

  return clusters;
});

/// Generates radiant multi-layered heatmap circles for Google Maps
final heatmapCirclesProvider = Provider<Set<Circle>>((ref) {
  final clusters = ref.watch(heatmapClustersProvider);
  final state = ref.watch(heatmapNotifierProvider);
  final Set<Circle> circles = {};

  for (final cluster in clusters) {
    final LatLng center = LatLng(cluster.latitude, cluster.longitude);
    final double baseRadius =
        80.0 * state.radiusMultiplier * (1.0 + (cluster.count - 1) * 0.25);

    if (state.mode == HeatmapMode.density) {
      // Density Mode: Heat gradient based on number of check-ins
      Color coreColor;
      if (cluster.count >= 6) {
        coreColor = const Color(
          0xFFFF3366,
        ); // Critical dense hotspot (Flame red)
      } else if (cluster.count >= 4) {
        coreColor = const Color(0xFFFF9900); // Dense (Amber orange)
      } else if (cluster.count >= 2) {
        coreColor = const Color(0xFF10B981); // Moderate (Emerald green)
      } else {
        coreColor = const Color(0xFF00D2FF); // Single / Light (Cyan neon)
      }

      // Layer 1: Ambient Outer Glow
      circles.add(
        Circle(
          circleId: CircleId('heat_glow_outer_${cluster.id}'),
          center: center,
          radius: baseRadius * 2.2,
          strokeWidth: 0,
          fillColor: coreColor.withAlpha(25), // ~10%
        ),
      );

      // Layer 2: Mid Aura
      circles.add(
        Circle(
          circleId: CircleId('heat_glow_mid_${cluster.id}'),
          center: center,
          radius: baseRadius * 1.3,
          strokeWidth: 0,
          fillColor: coreColor.withAlpha(65), // ~25%
        ),
      );

      // Layer 3: Hot Core Body
      circles.add(
        Circle(
          circleId: CircleId('heat_core_${cluster.id}'),
          center: center,
          radius: baseRadius * 0.65,
          strokeWidth: 0,
          fillColor: coreColor.withAlpha(140), // ~55%
        ),
      );

      // Layer 4: Nucleus Center
      circles.add(
        Circle(
          circleId: CircleId('heat_nucleus_${cluster.id}'),
          center: center,
          radius: baseRadius * 0.25,
          strokeWidth: 1,
          strokeColor: Colors.white.withAlpha(200),
          fillColor: coreColor.withAlpha(230),
        ),
      );
    } else if (state.mode == HeatmapMode.risk) {
      // Risk & Spoofing Heatmap Mode
      final bool isCritical =
          cluster.hasHighRisk || cluster.averageRiskScore >= 70;
      final bool isSuspicious =
          cluster.averageRiskScore >= 35 && cluster.averageRiskScore < 70;

      final Color riskColor = isCritical
          ? const Color(0xFFEF4444) // Rose Red Alert
          : (isSuspicious
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981)); // Amber vs Green

      // Outer Threat Ring
      circles.add(
        Circle(
          circleId: CircleId('risk_outer_${cluster.id}'),
          center: center,
          radius: baseRadius * (isCritical ? 2.5 : 1.8),
          strokeWidth: isCritical ? 2 : 0,
          strokeColor: riskColor.withAlpha(isCritical ? 180 : 0),
          fillColor: riskColor.withAlpha(isCritical ? 45 : 30),
        ),
      );

      // Mid Risk Aura
      circles.add(
        Circle(
          circleId: CircleId('risk_mid_${cluster.id}'),
          center: center,
          radius: baseRadius * 1.2,
          strokeWidth: 0,
          fillColor: riskColor.withAlpha(isCritical ? 100 : 70),
        ),
      );

      // Core Alert
      circles.add(
        Circle(
          circleId: CircleId('risk_core_${cluster.id}'),
          center: center,
          radius: baseRadius * 0.5,
          strokeWidth: 1,
          strokeColor: Colors.white.withAlpha(220),
          fillColor: riskColor.withAlpha(220),
        ),
      );
    } else {
      // Points Mode: Clean single geofence outline
      circles.add(
        Circle(
          circleId: CircleId('points_circle_${cluster.id}'),
          center: center,
          radius: 50.0 * state.radiusMultiplier,
          strokeWidth: 1,
          strokeColor: AppTheme.primary,
          fillColor: AppTheme.primary.withAlpha(40),
        ),
      );
    }
  }

  return circles;
});

/// Generates interactive Markers for all clusters/points
final heatmapMarkersProvider = Provider<Set<Marker>>((ref) {
  final clusters = ref.watch(heatmapClustersProvider);
  final state = ref.watch(heatmapNotifierProvider);
  final notifier = ref.watch(heatmapNotifierProvider.notifier);
  final Set<Marker> markers = {};

  for (final cluster in clusters) {
    final LatLng position = LatLng(cluster.latitude, cluster.longitude);
    final bool hasRisk = cluster.hasHighRisk;

    double hue;
    if (state.mode == HeatmapMode.density) {
      if (cluster.count >= 6) {
        hue = BitmapDescriptor.hueRed;
      } else if (cluster.count >= 4) {
        hue = BitmapDescriptor.hueOrange;
      } else if (cluster.count >= 2) {
        hue = BitmapDescriptor.hueGreen;
      } else {
        hue = BitmapDescriptor.hueCyan;
      }
    } else {
      hue = hasRisk
          ? BitmapDescriptor.hueRed
          : (cluster.averageRiskScore >= 35
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen);
    }

    markers.add(
      Marker(
        markerId: MarkerId('marker_${cluster.id}'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: "${cluster.primaryTargetName} (${cluster.count} Check-in)",
          snippet:
              "Ort. Risk: ${cluster.averageRiskScore.toStringAsFixed(0)}/100 • Güvenli: ${cluster.safeCount} • Tehdit: ${cluster.blockedCount}",
        ),
        onTap: () {
          notifier.selectCluster(cluster);
        },
      ),
    );
  }

  return markers;
});

/// Computed Analytics for Admin Dashboard
class HeatmapStats {
  final int totalRecords;
  final int totalClusters;
  final int safeRecords;
  final int riskyOrBlockedRecords;
  final double safePercentage;
  final double averageRiskScore;
  final String topHotspotName;
  final int topHotspotCount;
  final int vpnOrMockDetections;

  const HeatmapStats({
    required this.totalRecords,
    required this.totalClusters,
    required this.safeRecords,
    required this.riskyOrBlockedRecords,
    required this.safePercentage,
    required this.averageRiskScore,
    required this.topHotspotName,
    required this.topHotspotCount,
    required this.vpnOrMockDetections,
  });
}

final heatmapStatsProvider = Provider<HeatmapStats>((ref) {
  final records = ref.watch(filteredHeatmapRecordsProvider);
  final clusters = ref.watch(heatmapClustersProvider);

  if (records.isEmpty) {
    return const HeatmapStats(
      totalRecords: 0,
      totalClusters: 0,
      safeRecords: 0,
      riskyOrBlockedRecords: 0,
      safePercentage: 100.0,
      averageRiskScore: 0.0,
      topHotspotName: 'Kayıt Yok',
      topHotspotCount: 0,
      vpnOrMockDetections: 0,
    );
  }

  final safe = records.where((r) => !r.isBlocked && r.riskScore < 35).length;
  final riskyOrBlocked = records.length - safe;
  final safePct = (safe / records.length) * 100.0;
  final avgRisk =
      records.fold<int>(0, (sum, r) => sum + r.riskScore) / records.length;

  int vpnOrMockCount = 0;
  for (final r in records) {
    final status = r.deviceStatus.toLowerCase();
    if (status.contains('mock') ||
        status.contains('vpn: true') ||
        status.contains('rooted: true') ||
        status.contains('ışınlanma')) {
      vpnOrMockCount++;
    }
  }

  HeatmapCluster? topCluster;
  for (final c in clusters) {
    if (topCluster == null || c.count > topCluster.count) {
      topCluster = c;
    }
  }

  return HeatmapStats(
    totalRecords: records.length,
    totalClusters: clusters.length,
    safeRecords: safe,
    riskyOrBlockedRecords: riskyOrBlocked,
    safePercentage: safePct,
    averageRiskScore: avgRisk,
    topHotspotName: topCluster?.primaryTargetName ?? 'Kadıköy Meydan',
    topHotspotCount: topCluster?.count ?? 0,
    vpnOrMockDetections: vpnOrMockCount,
  );
});

double _calculateHaversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const double r = 6371000; // Radius of Earth in meters
  final double dLat = (lat2 - lat1) * pi / 180;
  final double dLon = (lon2 - lon1) * pi / 180;
  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}
