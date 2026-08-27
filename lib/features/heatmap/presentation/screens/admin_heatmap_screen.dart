import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/theme/app_theme.dart';
import '../../../location_map/presentation/widgets/city_selector_sheet.dart';
import '../providers/heatmap_providers.dart';
import '../widgets/heatmap_legend.dart';
import '../widgets/heatmap_stats_sheet.dart';
import '../widgets/heatmap_point_detail_dialog.dart';
import '../widgets/heatmap_radar_canvas.dart';

class AdminHeatmapScreen extends ConsumerStatefulWidget {
  const AdminHeatmapScreen({super.key});

  @override
  ConsumerState<AdminHeatmapScreen> createState() => _AdminHeatmapScreenState();
}

class _AdminHeatmapScreenState extends ConsumerState<AdminHeatmapScreen> {
  final MapController _osmMapController = MapController();
  String _selectedHub = '34 İstanbul';
  bool _useRadarCanvas = false;

  // Key Turkey Provincial Hub Locations for Quick Navigation
  static const Map<String, ll.LatLng> _hubs = {
    '34 İstanbul': ll.LatLng(41.0082, 28.9784),
    '06 Ankara': ll.LatLng(39.9334, 32.8597),
    '35 İzmir': ll.LatLng(38.4192, 27.1287),
    '16 Bursa': ll.LatLng(40.1885, 29.0610),
    '07 Antalya': ll.LatLng(36.8969, 30.7133),
    '01 Adana': ll.LatLng(37.0000, 35.3213),
    '61 Trabzon': ll.LatLng(41.0027, 39.7168),
    '27 Gaziantep': ll.LatLng(37.0662, 37.3833),
    '42 Konya': ll.LatLng(37.8746, 32.4932),
    '26 Eskişehir': ll.LatLng(39.7767, 30.5206),
  };

  void _navigateToLocation(
    String name,
    ll.LatLng target, {
    double zoom = 15.2,
  }) {
    setState(() {
      _selectedHub = name;
    });
    _osmMapController.move(target, zoom);
  }

  void _openStatsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HeatmapStatsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heatmapState = ref.watch(heatmapNotifierProvider);
    final heatmapNotifier = ref.read(heatmapNotifierProvider.notifier);
    final clusters = ref.watch(heatmapClustersProvider);
    final stats = ref.watch(heatmapStatsProvider);

    // Listen for cluster selection to open detail modal
    ref.listen<HeatmapState>(heatmapNotifierProvider, (previous, next) {
      if (next.selectedCluster != null &&
          previous?.selectedCluster != next.selectedCluster) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              HeatmapPointDetailDialog(cluster: next.selectedCluster!),
        ).whenComplete(() {
          heatmapNotifier.clearSelection();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("YÖNETİCİ ISI HARİTASI"),
        actions: [
          IconButton(
            tooltip: _useRadarCanvas
                ? "Gerçek Sokak Haritasına Geç (CartoDB)"
                : "Taktik Radar Görünümüne Geç",
            icon: Icon(
              _useRadarCanvas ? Icons.map_rounded : Icons.radar_rounded,
              color: _useRadarCanvas ? Colors.cyanAccent : AppTheme.primary,
            ),
            onPressed: () {
              setState(() {
                _useRadarCanvas = !_useRadarCanvas;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _useRadarCanvas
                        ? "🎯 Taktik Radar Modu Aktif (Çevrimdışı)"
                        : "🌑 Gerçek Sokak Isı Haritası Aktif (CartoDB Dark)",
                  ),
                  backgroundColor: AppTheme.primary,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Demo Küme Verisi Yükle",
            icon: const Icon(Icons.science_rounded, color: AppTheme.primary),
            onPressed: () async {
              await heatmapNotifier.seedHeatmapDemoData(ref);
              _navigateToLocation(
                'Kadıköy',
                _hubs['Kadıköy'] ?? const ll.LatLng(40.9905, 29.0255),
                zoom: 15.0,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "✅ 22 demo check-in kaydı yüklendi ve Kadıköy'e odaklanıldı!",
                    ),
                    backgroundColor: AppTheme.safe,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: "Analitik ve İstatistikler",
            icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
            onPressed: _openStatsSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Map View (Tactical Radar Canvas OR Real Street CartoDB Dark Map - Zero API Key)
          if (_useRadarCanvas)
            HeatmapRadarCanvas(
              clusters: clusters,
              mode: heatmapState.mode,
              selectedHub: _selectedHub,
              onClusterTap: (cluster) {
                heatmapNotifier.selectCluster(cluster);
              },
            )
          else
            FlutterMap(
              mapController: _osmMapController,
              options: const MapOptions(
                initialCenter: ll.LatLng(40.9905, 29.0255),
                initialZoom: 14.5,
                minZoom: 3.0,
                maxZoom: 19.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.waypoint_app',
                  maxZoom: 19,
                  maxNativeZoom: 16,
                ),
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.waypoint_app',
                  maxZoom: 19,
                  maxNativeZoom: 16,
                ),
                CircleLayer(
                  circles: clusters.map((cluster) {
                    final color = heatmapState.mode == HeatmapMode.risk
                        ? (cluster.averageRiskScore < 35
                              ? AppTheme.safe
                              : (cluster.averageRiskScore < 70
                                    ? AppTheme.suspicious
                                    : AppTheme.spoofed))
                        : AppTheme.primary;
                    return CircleMarker(
                      point: ll.LatLng(cluster.latitude, cluster.longitude),
                      radius: (cluster.densityLevel * 60.0).clamp(40.0, 300.0),
                      useRadiusInMeter: true,
                      color: color.withAlpha(85),
                      borderColor: color,
                      borderStrokeWidth: 2.0,
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: clusters.map((cluster) {
                    final color = heatmapState.mode == HeatmapMode.risk
                        ? (cluster.averageRiskScore < 35
                              ? AppTheme.safe
                              : (cluster.averageRiskScore < 70
                                    ? AppTheme.suspicious
                                    : AppTheme.spoofed))
                        : AppTheme.primary;
                    return Marker(
                      point: ll.LatLng(cluster.latitude, cluster.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => heatmapNotifier.selectCluster(cluster),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withAlpha(240),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(90),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "${cluster.count}",
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          // 2. Top Control Panel (Mode Selector & Filters)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Mode Toggle Bar (Density vs Risk vs Points)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withAlpha(240),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A3547)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(120),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildModeButton(
                        icon: Icons.whatshot_rounded,
                        label: "Yoğunluk",
                        mode: HeatmapMode.density,
                        currentMode: heatmapState.mode,
                        onTap: () =>
                            heatmapNotifier.setMode(HeatmapMode.density),
                        activeColor: const Color(0xFFFF9900),
                      ),
                      _buildModeButton(
                        icon: Icons.shield_rounded,
                        label: "Risk / Tehdit",
                        mode: HeatmapMode.risk,
                        currentMode: heatmapState.mode,
                        onTap: () => heatmapNotifier.setMode(HeatmapMode.risk),
                        activeColor: AppTheme.spoofed,
                      ),
                      _buildModeButton(
                        icon: Icons.pin_drop_rounded,
                        label: "Noktasal",
                        mode: HeatmapMode.points,
                        currentMode: heatmapState.mode,
                        onTap: () =>
                            heatmapNotifier.setMode(HeatmapMode.points),
                        activeColor: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: "Tümü (${stats.totalRecords})",
                        isSelected: heatmapState.riskFilter == RiskFilter.all,
                        onTap: () =>
                            heatmapNotifier.setRiskFilter(RiskFilter.all),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: "🟢 Güvenli (${stats.safeRecords})",
                        isSelected:
                            heatmapState.riskFilter == RiskFilter.safeOnly,
                        onTap: () =>
                            heatmapNotifier.setRiskFilter(RiskFilter.safeOnly),
                        accentColor: AppTheme.safe,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: "🔴 Tehditler (${stats.riskyOrBlockedRecords})",
                        isSelected:
                            heatmapState.riskFilter == RiskFilter.riskyOnly,
                        onTap: () =>
                            heatmapNotifier.setRiskFilter(RiskFilter.riskyOnly),
                        accentColor: AppTheme.spoofed,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: "⏱️ Son 24s",
                        isSelected:
                            heatmapState.timeFilter == TimeFilter.last24Hours,
                        onTap: () {
                          if (heatmapState.timeFilter ==
                              TimeFilter.last24Hours) {
                            heatmapNotifier.setTimeFilter(TimeFilter.allTime);
                          } else {
                            heatmapNotifier.setTimeFilter(
                              TimeFilter.last24Hours,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Quick Hub Jump Buttons (81 İl Seçici + Büyükşehir Merkezleri)
          Positioned(
            left: 12,
            right: 12,
            bottom: 74,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 81 Province Modal Trigger
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => CitySelectorSheet.show(
                        context,
                        onProvinceSelected: (province) {
                          _navigateToLocation(
                            "${province.formattedPlate} ${province.name}",
                            ll.LatLng(province.latitude, province.longitude),
                            zoom: 14.5,
                          );
                        },
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D2FF), Color(0xFF9D4EDD)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.travel_explore_rounded,
                              size: 14,
                              color: Colors.black,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "81 İl Seçici",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._hubs.entries.map((entry) {
                    final bool isSelected = _selectedHub == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () =>
                            _navigateToLocation(entry.key, entry.value),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surface.withAlpha(235),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : const Color(0xFF2A3547),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(90),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me_rounded,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 4. Bottom Analytics Quick Bar (Tappable Pill)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: InkWell(
              onTap: _openStatsSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(245),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A3547)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(140),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${stats.totalRecords} Check-in • %${stats.safePercentage.toStringAsFixed(0)} Güvenli",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "Hotspot: ${stats.topHotspotName} (${stats.topHotspotCount})",
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          "Detaylar",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.primary,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Floating Heatmap Legend (Top-Right)
          Positioned(
            top: 110,
            right: 12,
            child: HeatmapLegend(mode: heatmapState.mode),
          ),

          // 6. Empty State Banner (If no check-ins loaded yet)
          if (stats.totalRecords == 0)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(245),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(160),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.whatshot_rounded,
                        color: AppTheme.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Isı Haritasında Henüz Veri Yok",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Renkli ısı ve tehlike halkalarını görmek için aşağıdaki butona basarak İstanbul geneli 22 demo kaydını yükleyin:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await heatmapNotifier.seedHeatmapDemoData(ref);
                        _navigateToLocation(
                          'Kadıköy',
                          _hubs['Kadıköy']!,
                          zoom: 15.0,
                        );
                      },
                      icon: const Icon(
                        Icons.science_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        "Demo Verilerini Yükle & Başlat 🚀",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required HeatmapMode mode,
    required HeatmapMode currentMode,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    final bool isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: activeColor, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final effectiveColor = accentColor ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withAlpha(35)
              : AppTheme.surface.withAlpha(220),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : const Color(0xFF2A3547),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? effectiveColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
