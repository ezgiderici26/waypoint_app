import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/theme/app_theme.dart';
import '../providers/location_providers.dart';
import '../providers/province_providers.dart';
import '../providers/antispoofing_providers.dart';
import '../widgets/city_selector_sheet.dart';
import '../widgets/open_street_map_view.dart';
import '../../../check_in/presentation/providers/check_in_providers.dart';
import '../../../security/presentation/providers/security_providers.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/constants/turkey_provinces.dart';
import '../providers/geofence_providers.dart';
import '../../../heatmap/presentation/screens/admin_heatmap_screen.dart';
import '../widgets/main_radar_canvas.dart';

class MainMapScreen extends ConsumerStatefulWidget {
  const MainMapScreen({super.key});

  @override
  ConsumerState<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends ConsumerState<MainMapScreen> {
  final MapController _osmController = MapController();
  MapTileStyle _tileStyle = MapTileStyle.darkCyberpunk;
  bool _useRadarCanvas = false;
  bool _isMapReady = false;

  void _safeMoveMap(ll.LatLng target, double zoom) {
    if (!_useRadarCanvas && _isMapReady) {
      try {
        _osmController.move(target, zoom);
      } catch (e) {
        debugPrint("Map move error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch live location stream, geofence, province, and distance
    final locationAsync = ref.watch(locationStreamProvider);
    final distanceToTarget = ref.watch(distanceToTargetProvider);
    final target = ref.watch(targetLocationProvider);
    final geofenceState = ref.watch(geofenceProvider);
    final selectedProvince = ref.watch(selectedProvinceProvider);

    // 2. Watch real-time antispoofing and risk scoring
    final riskState = ref.watch(antispoofingProvider);
    final int riskScore = riskState.riskScore;

    // 3. Listen to location changes to animate camera and auto-detect nearest province
    ref.listen(locationStreamProvider, (previous, next) {
      next.whenData((location) {
        _safeMoveMap(
          ll.LatLng(location.latitude, location.longitude),
          15.0,
        );

        // Auto-detect nearest province if using real GPS (not simulated)
        // and the current selected province does not match the physically nearest province
        final isSimulated = ref.read(simulatedUserLocationProvider) != null;
        if (!isSimulated) {
          final nearest = TurkeyProvinces.findNearest(
            location.latitude,
            location.longitude,
          );
          final currentSelected = ref.read(selectedProvinceProvider);
          if (currentSelected.plateCode != nearest.plateCode) {
            ref
                .read(selectedProvinceProvider.notifier)
                .autoDetectNearest(location);
          }
        }
      });
    });

    // 4. Listen to province changes to animate camera to the selected city center
    ref.listen(selectedProvinceProvider, (previous, next) {
      if (previous?.plateCode != next.plateCode) {
        _safeMoveMap(ll.LatLng(next.latitude, next.longitude), 15.0);
      }
    });

    // Determine if check-in is allowed (Must be within geofence and risk score must be SAFE < 35)
    final bool isInsideGeofence =
        distanceToTarget != null && distanceToTarget <= target.radius;
    final bool isSafe = riskScore < 35;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => CitySelectorSheet.show(
            context,
            onProvinceSelected: (province) {
              _safeMoveMap(
                ll.LatLng(province.latitude, province.longitude),
                15.0,
              );
            },
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(120)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    selectedProvince.formattedPlate,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    selectedProvince.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
        actions: [
          // 81 Province Selector
          IconButton(
            tooltip: "81 İl Seçici",
            icon: const Icon(
              Icons.travel_explore_rounded,
              color: AppTheme.primary,
            ),
            onPressed: () => CitySelectorSheet.show(
              context,
              onProvinceSelected: (province) {
                _safeMoveMap(
                  ll.LatLng(province.latitude, province.longitude),
                  15.0,
                );
              },
            ),
          ),

          // Focus on My Location
          IconButton(
            tooltip: "Konumuma Odaklan",
            icon: const Icon(Icons.my_location_rounded, color: AppTheme.safe),
            onPressed: () {
              final currentLoc = locationAsync.value;
              if (currentLoc != null) {
                _safeMoveMap(
                  ll.LatLng(currentLoc.latitude, currentLoc.longitude),
                  16.0,
                );
              }
            },
          ),

          // Quick Action & Theme Popup Menu
          PopupMenuButton<String>(
            tooltip: "Menü & Harita Katmanları",
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.primary),
            color: AppTheme.surface,
            onSelected: (val) {
              if (val == 'target_here') {
                final currentLoc = locationAsync.value;
                if (currentLoc != null) {
                  ref
                      .read(targetLocationProvider.notifier)
                      .state = TargetLocation(
                    name: "Mevcut Konumum (Canlı GPS)",
                    latitude: currentLoc.latitude,
                    longitude: currentLoc.longitude,
                    radius: target.radius,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "📍 Konumunuz (${currentLoc.latitude.toStringAsFixed(4)}, ${currentLoc.longitude.toStringAsFixed(4)}) hedef yapıldı!",
                      ),
                      backgroundColor: AppTheme.safe,
                    ),
                  );
                }
                return;
              }

              if (val == 'heatmap') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminHeatmapScreen()),
                );
                return;
              }

              setState(() {
                if (val == 'radar') {
                  _useRadarCanvas = true;
                } else if (val == 'dark') {
                  _useRadarCanvas = false;
                  _tileStyle = MapTileStyle.darkCyberpunk;
                } else if (val == 'satellite') {
                  _useRadarCanvas = false;
                  _tileStyle = MapTileStyle.satelliteHybrid;
                } else if (val == 'osm') {
                  _useRadarCanvas = false;
                  _tileStyle = MapTileStyle.streetOpenMap;
                } else if (val == 'modern') {
                  _useRadarCanvas = false;
                  _tileStyle = MapTileStyle.streetModern;
                }
              });
              if (!_useRadarCanvas) {
                final currentLoc = locationAsync.value;
                if (currentLoc != null) {
                  _osmController.move(
                    ll.LatLng(currentLoc.latitude, currentLoc.longitude),
                    15.0,
                  );
                } else {
                  _osmController.move(
                    ll.LatLng(selectedProvince.latitude, selectedProvince.longitude),
                    15.0,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'dark',
                child: Row(
                  children: [
                    Icon(
                      Icons.dark_mode_rounded,
                      color: Colors.cyanAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "🌑 Cyberpunk Dark",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'satellite',
                child: Row(
                  children: [
                    Icon(
                      Icons.satellite_alt_rounded,
                      color: Colors.lightGreenAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "🛰️ Gerçek Uydu Haritası",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'osm',
                child: Row(
                  children: [
                    Icon(
                      Icons.map_rounded,
                      color: Colors.amberAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "🗺️ Klasik Sokak Haritası",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'modern',
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city_rounded,
                      color: Colors.orangeAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "🏙️ Modern Cadde Haritası",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'radar',
                child: Row(
                  children: [
                    Icon(
                      Icons.radar_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "📡 Taktik Radar (Çevrimdışı)",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'target_here',
                child: Row(
                  children: [
                    Icon(
                      Icons.add_location_alt_rounded,
                      color: AppTheme.safe,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "📍 Burayı Hedef Geofence Yap",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'heatmap',
                child: Row(
                  children: [
                    Icon(
                      Icons.whatshot_rounded,
                      color: Colors.deepOrangeAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "📊 Yönetici Isı Haritası",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Real Street/City Map View (CartoDB Dark / OpenStreetMap - Zero API Key) OR Tactical Radar
          _useRadarCanvas
              ? MainRadarCanvas(
                  userLocation: locationAsync.value,
                  targetLocation: target,
                  selectedProvince: selectedProvince,
                  riskScore: riskScore,
                  isInsideGeofence: isInsideGeofence,
                  distanceToTarget: distanceToTarget,
                  onOpenCitySelector: () => CitySelectorSheet.show(
                    context,
                    onProvinceSelected: (province) {
                      _safeMoveMap(
                        ll.LatLng(province.latitude, province.longitude),
                        15.0,
                      );
                    },
                  ),
                )
              : OpenStreetMapWidget(
                  userLocation: locationAsync.value,
                  targetLocation: target,
                  selectedProvince: selectedProvince,
                  riskScore: riskScore,
                  isInsideGeofence: isInsideGeofence,
                  distanceToTarget: distanceToTarget,
                  mapController: _osmController,
                  tileStyle: _tileStyle,
                  onMapReady: () {
                    setState(() {
                      _isMapReady = true;
                    });
                  },
                ),

          // 2. Top Info Overlay (Risk Status Chip)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRiskChip(riskScore),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withAlpha(204),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2A3547)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.radar,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Mock GPS Koruması: AKTİF",
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 81 Province Quick Selector Card
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => CitySelectorSheet.show(
                      context,
                      onProvinceSelected: (province) {
                        _safeMoveMap(
                          ll.LatLng(province.latitude, province.longitude),
                          15.0,
                        );
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withAlpha(240),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(140),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(120),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedProvince.formattedPlate,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      selectedProvince.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        selectedProvince.region,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "Hedef: ${selectedProvince.defaultCheckpointName} (200m) • Değiştir ▼",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primary.withAlpha(220),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.tune_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Quick Province Teleport & Real GPS Toggle Buttons
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      // Direct Button: "📍 [İl Adı]'na Işınlan / Hedefe Gir"
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            ref
                                .read(selectedProvinceProvider.notifier)
                                .selectProvince(
                                  selectedProvince,
                                  moveUserToProvince: true,
                                );
                            _safeMoveMap(
                              ll.LatLng(
                                selectedProvince.latitude,
                                selectedProvince.longitude,
                              ),
                              16.5,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "📍 Konumunuz ${selectedProvince.name} (${selectedProvince.defaultCheckpointName}) merkezine alındı! Check-in aktif.",
                                ),
                                backgroundColor: AppTheme.safe,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isInsideGeofence
                                  ? AppTheme.safe.withAlpha(45)
                                  : AppTheme.primary.withAlpha(35),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isInsideGeofence
                                    ? AppTheme.safe
                                    : AppTheme.primary,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isInsideGeofence
                                      ? Icons.check_circle_rounded
                                      : Icons.gps_fixed_rounded,
                                  color: isInsideGeofence
                                      ? AppTheme.safe
                                      : AppTheme.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isInsideGeofence
                                      ? "📍 ${selectedProvince.name}'desiniz (Check-in Açık)"
                                      : "Konumumu ${selectedProvince.name}'ye Al",
                                  style: TextStyle(
                                    color: isInsideGeofence
                                        ? AppTheme.safe
                                        : AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Reset to Hardware GPS Sensor
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          ref
                              .read(selectedProvinceProvider.notifier)
                              .useRealGps();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "📡 Cihazın canlı GPS sensörüne dönüldü.",
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sensors_rounded,
                                color: AppTheme.textSecondary,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Gerçek GPS",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Anomaly Warning Banners
                if (riskState.isOsMocked) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner(
                    "OS Mock Sağlayıcısı Algılandı! (K1)",
                    Icons.gpp_bad_rounded,
                  ),
                ],
                if (riskState.isSpeedImpossible) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner(
                    "İmkânsız Hız / Işınlanma Algılandı! (K4) (${riskState.computedSpeedKmh.toStringAsFixed(1)} km/s)",
                    Icons.speed_rounded,
                  ),
                ],
                if (riskState.isDevModeActive) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner(
                    "Geliştirici Modu / USB Hata Ayıklama Etkin! (K3)",
                    Icons.developer_mode_rounded,
                  ),
                ],
                if (riskState.isSensorInconsistent) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner(
                    "Sensör ve Hız Tutarsızlığı Algılandı! (K5)",
                    Icons.sensors_off_rounded,
                  ),
                ],
                if (geofenceState.isInside) ...[
                  const SizedBox(height: 10),
                  _buildGeofenceSuccessBanner(
                    "📍 Hedef Kontrol Alanı İçindesiniz (${target.name})",
                    Icons.verified_rounded,
                  ),
                ],
              ],
            ),
          ),

          // 3. Floating Quick Action Controls (Konumuma Git & Hedefe Git)
          Positioned(
            bottom: 225,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Focus on Target Geofence Button
                FloatingActionButton.small(
                  heroTag: "fab_target",
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: AppTheme.primary,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  tooltip: "Hedef Geofence Noktasına Git",
                  onPressed: () {
                    _safeMoveMap(
                      ll.LatLng(target.latitude, target.longitude),
                      16.0,
                    );
                  },
                  child: const Icon(Icons.flag_rounded, size: 20),
                ),
                const SizedBox(height: 10),
                // Focus on User Live GPS Location Button
                FloatingActionButton.extended(
                  heroTag: "fab_my_loc",
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tooltip: "Canlı GPS Konumuma Odaklan",
                  icon: const Icon(Icons.my_location_rounded, size: 20),
                  label: const Text(
                    "Konumuma Git",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: () {
                    final currentLoc = locationAsync.value;
                    if (currentLoc != null) {
                      _safeMoveMap(
                        ll.LatLng(currentLoc.latitude, currentLoc.longitude),
                        16.5,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "📡 GPS konumu alınıyor, lütfen bekleyin...",
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // 4. Bottom HUD Panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live Location Stream Info Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withAlpha(229),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3547)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(128),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      locationAsync.maybeWhen(
                        data: (data) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCoordCol(
                              "Enlem",
                              data.latitude.toStringAsFixed(6),
                            ),
                            _buildCoordCol(
                              "Boylam",
                              data.longitude.toStringAsFixed(6),
                            ),
                            _buildCoordCol(
                              "Hız",
                              riskState.computedSpeedKmh > 0
                                  ? "${riskState.computedSpeedKmh.toStringAsFixed(1)} km/s"
                                  : "${(data.speed * 3.6).toStringAsFixed(1)} km/s",
                            ),
                            _buildCoordCol(
                              "Doğruluk (Acc)",
                              "${data.accuracy.toStringAsFixed(1)}m",
                            ),
                          ],
                        ),
                        orElse: () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCoordCol("Enlem", "--"),
                            _buildCoordCol("Boylam", "--"),
                            _buildCoordCol("Hız", "-- km/s"),
                            _buildCoordCol("Doğruluk (Acc)", "--"),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF2A3547), height: 24),

                      // Geofencing Target Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hedef: ${target.name}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                _buildDistanceText(
                                  distanceToTarget,
                                  target.radius,
                                  onSetCurrentAsTarget: () {
                                    final currentLoc = locationAsync.value;
                                    if (currentLoc != null) {
                                      ref
                                          .read(targetLocationProvider.notifier)
                                          .state = TargetLocation(
                                        name: "Mevcut Konumum (Canlı GPS)",
                                        latitude: currentLoc.latitude,
                                        longitude: currentLoc.longitude,
                                        radius: target.radius,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "📍 Bulunduğunuz yer (${currentLoc.latitude.toStringAsFixed(4)}, ${currentLoc.longitude.toStringAsFixed(4)}) hedef kontrol alanı yapıldı!",
                                          ),
                                          backgroundColor: AppTheme.safe,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isInsideGeofence
                                ? () async {
                                    final biometricService = ref.read(
                                      biometricServiceProvider,
                                    );

                                    // Check availability of biometric hardware first
                                    final bool available =
                                        await biometricService
                                            .isBiometricsAvailable();
                                    if (!available) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Biyometrik donanım bulunamadı veya etkinleştirilmedi!",
                                            ),
                                            backgroundColor: AppTheme.spoofed,
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    // Trigger biometric scan prompt
                                    final bool success = await biometricService
                                        .authenticate();
                                    if (!success) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Biyometrik doğrulama reddedildi! İşlem iptal edildi.",
                                            ),
                                            backgroundColor: AppTheme.spoofed,
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    final currentLoc = locationAsync.value;
                                    final security = ref.read(securityProvider);
                                    final devStatus =
                                        "Rooted: ${security.isJailbroken}, Emulator: ${security.isEmulator}, VPN: ${security.isVpnActive}";

                                    if (currentLoc != null) {
                                      ref
                                          .read(checkInHistoryProvider.notifier)
                                          .addCheckInRecord(
                                            latitude: currentLoc.latitude,
                                            longitude: currentLoc.longitude,
                                            accuracy: currentLoc.accuracy,
                                            riskScore: riskScore,
                                            deviceStatus: devStatus,
                                            targetName: target.name,
                                            isBlocked: !isSafe,
                                            plateCode:
                                                selectedProvince.plateCode,
                                          );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isSafe
                                                  ? "Biyometrik doğrulama başarılı. Check-in eklendi!"
                                                  : "Güvenlik Engeli: Tehdit nedeniyle işlem engellendi!",
                                            ),
                                            backgroundColor: isSafe
                                                ? AppTheme.safe
                                                : AppTheme.spoofed,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              disabledBackgroundColor: AppTheme.textSecondary
                                  .withAlpha(51),
                            ),
                            child: const Text("Check-in Yap"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.spoofed.withAlpha(204),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.spoofed),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceSuccessBanner(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.safe.withAlpha(220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.safe),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceText(
    double? distance,
    double radius, {
    VoidCallback? onSetCurrentAsTarget,
  }) {
    if (distance == null) {
      return const Text(
        "Mesafe Hesaplanıyor...",
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      );
    }

    final bool isInside = distance <= radius;
    if (isInside) {
      return Text(
        "Hedefe ${distance.toStringAsFixed(0)} m (Yarıçap içinde)",
        style: const TextStyle(
          color: AppTheme.safe,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final String distStr = (distance >= 1000)
        ? "${(distance / 1000).toStringAsFixed(1)} km"
        : "${distance.toStringAsFixed(0)} m";

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Hedefe $distStr uzaktasın",
          style: const TextStyle(
            color: AppTheme.suspicious,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSetCurrentAsTarget != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onSetCurrentAsTarget,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primary, width: 0.8),
              ),
              child: const Text(
                "📍 Burayı Hedef Yap",
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCoordCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskChip(int score) {
    Color chipColor;
    String text;
    IconData icon;

    if (score < 35) {
      chipColor = AppTheme.safe;
      text = "GÜVENLİ ($score/100)";
      icon = Icons.check_circle_rounded;
    } else if (score < 70) {
      chipColor = AppTheme.suspicious;
      text = "ŞÜPHELİ ($score/100)";
      icon = Icons.warning_rounded;
    } else {
      chipColor = AppTheme.spoofed;
      text = "SAHTE ($score/100)";
      icon = Icons.gpp_bad_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
