import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/heatmap_providers.dart';
import '../widgets/heatmap_legend.dart';
import '../widgets/heatmap_stats_sheet.dart';
import '../widgets/heatmap_point_detail_dialog.dart';

class AdminHeatmapScreen extends ConsumerStatefulWidget {
  const AdminHeatmapScreen({super.key});

  @override
  ConsumerState<AdminHeatmapScreen> createState() => _AdminHeatmapScreenState();
}

class _AdminHeatmapScreenState extends ConsumerState<AdminHeatmapScreen> {
  GoogleMapController? _mapController;

  // Istanbul Central Coordinates
  static const LatLng _initialPosition = LatLng(41.0200, 29.0050);

  // Key Istanbul Hub Locations for Quick Navigation
  static const Map<String, LatLng> _hubs = {
    'Kadıköy': LatLng(40.9905, 29.0255),
    'Beşiktaş': LatLng(41.0428, 29.0075),
    'Taksim': LatLng(41.0370, 28.9850),
    'Levent': LatLng(41.0822, 29.0125),
    'Maslak': LatLng(41.1060, 29.0240),
  };

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _navigateToLocation(LatLng target, {double zoom = 15.2}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
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
    final circles = ref.watch(heatmapCirclesProvider);
    final markers = ref.watch(heatmapMarkersProvider);
    final stats = ref.watch(heatmapStatsProvider);

    // Listen for cluster selection to open detail modal
    ref.listen<HeatmapState>(heatmapNotifierProvider, (previous, next) {
      if (next.selectedCluster != null && previous?.selectedCluster != next.selectedCluster) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => HeatmapPointDetailDialog(cluster: next.selectedCluster!),
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
            tooltip: "Demo Küme Verisi Yükle",
            icon: const Icon(Icons.science_rounded, color: AppTheme.primary),
            onPressed: () async {
              await heatmapNotifier.seedHeatmapDemoData(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("İstanbul geneli 22 demo check-in kaydı yüklendi!"),
                    backgroundColor: AppTheme.safe,
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
          // 1. Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 12.8,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            circles: circles,
            markers: markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
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
                        onTap: () => heatmapNotifier.setMode(HeatmapMode.density),
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
                        onTap: () => heatmapNotifier.setMode(HeatmapMode.points),
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
                        onTap: () => heatmapNotifier.setRiskFilter(RiskFilter.all),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: "🟢 Güvenli (${stats.safeRecords})",
                        isSelected: heatmapState.riskFilter == RiskFilter.safeOnly,
                        onTap: () => heatmapNotifier.setRiskFilter(RiskFilter.safeOnly),
                        accentColor: AppTheme.safe,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: "🔴 Tehditler (${stats.riskyOrBlockedRecords})",
                        isSelected: heatmapState.riskFilter == RiskFilter.riskyOnly,
                        onTap: () => heatmapNotifier.setRiskFilter(RiskFilter.riskyOnly),
                        accentColor: AppTheme.spoofed,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: "⏱️ Son 24s",
                        isSelected: heatmapState.timeFilter == TimeFilter.last24Hours,
                        onTap: () {
                          if (heatmapState.timeFilter == TimeFilter.last24Hours) {
                            heatmapNotifier.setTimeFilter(TimeFilter.allTime);
                          } else {
                            heatmapNotifier.setTimeFilter(TimeFilter.last24Hours);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Quick Hub Jump Buttons (Kadıköy, Beşiktaş, Taksim, Levent, Maslak)
          Positioned(
            left: 12,
            right: 12,
            bottom: 74,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _hubs.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      backgroundColor: AppTheme.surface.withAlpha(220),
                      side: const BorderSide(color: Color(0xFF2A3547)),
                      avatar: const Icon(Icons.near_me_rounded, size: 14, color: AppTheme.primary),
                      label: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      ),
                      onPressed: () => _navigateToLocation(entry.value),
                    ),
                  );
                }).toList(),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          child: const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 18),
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
                        Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 12),
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
            border: isSelected ? Border.all(color: activeColor, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? activeColor : AppTheme.textSecondary),
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
          color: isSelected ? effectiveColor.withAlpha(35) : AppTheme.surface.withAlpha(220),
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
