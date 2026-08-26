import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/location_providers.dart';
import '../providers/antispoofing_providers.dart';
import '../../../check_in/presentation/providers/check_in_providers.dart';
import '../../../security/presentation/providers/security_providers.dart';
import '../../../../core/services/biometric_service.dart';

class MainMapScreen extends ConsumerStatefulWidget {
  const MainMapScreen({super.key});

  @override
  ConsumerState<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends ConsumerState<MainMapScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch live location stream and distance
    final locationAsync = ref.watch(locationStreamProvider);
    final distanceToTarget = ref.watch(distanceToTargetProvider);
    final target = ref.watch(targetLocationProvider);

    // 2. Watch real-time antispoofing and risk scoring
    final riskState = ref.watch(antispoofingProvider);
    final int riskScore = riskState.riskScore;

    // 3. Listen to location changes to animate camera
    ref.listen(locationStreamProvider, (previous, next) {
      next.whenData((location) {
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(location.latitude, location.longitude),
            ),
          );
        }
      });
    });

    // Determine user position for map
    final LatLng? userLatLng = locationAsync.maybeWhen(
      data: (data) => LatLng(data.latitude, data.longitude),
      orElse: () => null,
    );

    final LatLng targetLatLng = LatLng(target.latitude, target.longitude);

    // 4. Configure Markers
    final Set<Marker> markers = {
      // Target Marker
      Marker(
        markerId: const MarkerId('target'),
        position: targetLatLng,
        infoWindow: InfoWindow(title: "Hedef: ${target.name}"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    };

    if (userLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          infoWindow: InfoWindow(
            title: "Mevcut Konumunuz",
            snippet: "Risk Skoru: $riskScore/100",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            riskScore < 35 
                ? BitmapDescriptor.hueGreen 
                : (riskScore < 70 ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed),
          ),
        ),
      );
    }

    // 5. Configure Circles (Geofence Yarıçapı)
    final Set<Circle> circles = {
      Circle(
        circleId: const CircleId('geofence'),
        center: targetLatLng,
        radius: target.radius,
        strokeWidth: 2,
        strokeColor: AppTheme.primary,
        fillColor: AppTheme.primary.withAlpha(38),
      ),
    };

    // Determine if check-in is allowed (Must be within geofence and risk score must be SAFE < 35)
    final bool isInsideGeofence = distanceToTarget != null && distanceToTarget <= target.radius;
    final bool isSafe = riskScore < 35;

    return Scaffold(
      appBar: AppBar(
        title: const Text("WAYPOINT HARİTA"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              if (userLatLng != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: userLatLng, zoom: 16),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Google Maps View
          locationAsync.when(
            data: (_) => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userLatLng ?? targetLatLng,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: markers,
              circles: circles,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            error: (err, stack) => Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.spoofed),
                    const SizedBox(height: 16),
                    const Text("Bağlantı Hatası", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withAlpha(204),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2A3547)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.radar, color: AppTheme.primary, size: 16),
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
                
                // Anomaly Warning Banners
                if (riskState.isOsMocked) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner("OS Mock Sağlayıcısı Algılandı! (K1)", Icons.gpp_bad_rounded),
                ],
                if (riskState.isSpeedImpossible) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner("İmkânsız Hız / Işınlanma Algılandı! (K4) (${riskState.computedSpeedKmh.toStringAsFixed(1)} km/s)", Icons.speed_rounded),
                ],
                if (riskState.isDevModeActive) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner("Geliştirici Modu / USB Hata Ayıklama Etkin! (K3)", Icons.developer_mode_rounded),
                ],
                if (riskState.isSensorInconsistent) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner("Sensör ve Hız Tutarsızlığı Algılandı! (K5)", Icons.sensors_off_rounded),
                ],
              ],
            ),
          ),

          // 3. Bottom HUD Panel
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
                            _buildCoordCol("Enlem", data.latitude.toStringAsFixed(6)),
                            _buildCoordCol("Boylam", data.longitude.toStringAsFixed(6)),
                            _buildCoordCol(
                              "Hız", 
                              riskState.computedSpeedKmh > 0
                                  ? "${riskState.computedSpeedKmh.toStringAsFixed(1)} km/s"
                                  : "${(data.speed * 3.6).toStringAsFixed(1)} km/s",
                            ),
                            _buildCoordCol("Doğruluk (Acc)", "${data.accuracy.toStringAsFixed(1)}m"),
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
                                _buildDistanceText(distanceToTarget, target.radius),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isInsideGeofence ? () async {
                              final biometricService = ref.read(biometricServiceProvider);
                              
                              // Check availability of biometric hardware first
                              final bool available = await biometricService.isBiometricsAvailable();
                              if (!available) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Biyometrik donanım bulunamadı veya etkinleştirilmedi!"),
                                      backgroundColor: AppTheme.spoofed,
                                    ),
                                  );
                                }
                                return;
                              }

                              // Trigger biometric scan prompt
                              final bool success = await biometricService.authenticate();
                              if (!success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Biyometrik doğrulama reddedildi! İşlem iptal edildi."),
                                      backgroundColor: AppTheme.spoofed,
                                    ),
                                  );
                                }
                                return;
                              }

                              final currentLoc = locationAsync.value;
                              final security = ref.read(securityProvider);
                              final devStatus = "Rooted: ${security.isJailbroken}, Emulator: ${security.isEmulator}, VPN: ${security.isVpnActive}";
                              
                              if (currentLoc != null) {
                                ref.read(checkInHistoryProvider.notifier).addCheckInRecord(
                                  latitude: currentLoc.latitude,
                                  longitude: currentLoc.longitude,
                                  accuracy: currentLoc.accuracy,
                                  riskScore: riskScore,
                                  deviceStatus: devStatus,
                                  targetName: target.name,
                                  isBlocked: !isSafe,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isSafe 
                                            ? "Biyometrik doğrulama başarılı. Check-in eklendi!"
                                            : "Güvenlik Engeli: Tehdit nedeniyle işlem engellendi!",
                                      ),
                                      backgroundColor: isSafe ? AppTheme.safe : AppTheme.spoofed,
                                    ),
                                  );
                                }
                              }
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              disabledBackgroundColor: AppTheme.textSecondary.withAlpha(51),
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

  Widget _buildDistanceText(double? distance, double radius) {
    if (distance == null) {
      return const Text(
        "Mesafe Hesaplanıyor...",
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      );
    }

    final bool isInside = distance <= radius;
    return Text(
      isInside 
          ? "Hedefe ${distance.toStringAsFixed(0)} m (Yarıçap içinde)" 
          : "Hedefe ${distance.toStringAsFixed(0)} m uzaktasın",
      style: TextStyle(
        color: isInside ? AppTheme.safe : AppTheme.suspicious,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
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
