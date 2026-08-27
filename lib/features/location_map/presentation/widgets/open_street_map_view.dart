import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/location_data.dart';
import '../providers/location_providers.dart';
import '../../../../core/constants/turkey_provinces.dart';

enum MapTileStyle {
  darkCyberpunk,   // 🌑 Cyberpunk Dark (ESRI Dark Gray Canvas - Zero Key, Zero Watermark)
  streetOpenMap,   // 🗺️ Klasik Sokak Haritası (OpenStreetMap - Zero Key, Zero Watermark)
  satelliteHybrid, // 🛰️ Gerçek Uydu Görünümü (ESRI World Imagery - Zero Key, Zero Watermark)
  streetModern,    // 🏙️ Modern Cadde Haritası (ESRI World Street - Zero Key, Zero Watermark)
}

class OpenStreetMapWidget extends StatefulWidget {
  final LocationData? userLocation;
  final TargetLocation targetLocation;
  final TurkeyProvince selectedProvince;
  final int riskScore;
  final bool isInsideGeofence;
  final double? distanceToTarget;
  final MapController mapController;
  final MapTileStyle tileStyle;

  const OpenStreetMapWidget({
    super.key,
    required this.userLocation,
    required this.targetLocation,
    required this.selectedProvince,
    required this.riskScore,
    required this.isInsideGeofence,
    required this.distanceToTarget,
    required this.mapController,
    this.tileStyle = MapTileStyle.darkCyberpunk,
  });

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  bool _isMapReady = false;

  @override
  void didUpdateWidget(OpenStreetMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMapReady) return;

    // 1. Auto-center on user GPS when coordinates arrive for the first time
    if (oldWidget.userLocation == null && widget.userLocation != null) {
      widget.mapController.move(
        ll.LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude),
        16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLoc = widget.userLocation;
    final target = widget.targetLocation;

    // Initial center prefers User GPS, falls back to Target
    final initialCenter = userLoc != null
        ? ll.LatLng(userLoc.latitude, userLoc.longitude)
        : ll.LatLng(target.latitude, target.longitude);

    final Color userRiskColor = widget.riskScore < 35
        ? AppTheme.safe
        : (widget.riskScore < 70 ? AppTheme.suspicious : AppTheme.spoofed);

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16.0,
        minZoom: 3.0,
        maxZoom: 19.0,
        onMapReady: () {
          _isMapReady = true;
          if (widget.userLocation != null) {
            widget.mapController.move(
              ll.LatLng(
                widget.userLocation!.latitude,
                widget.userLocation!.longitude,
              ),
              16.0,
            );
          }
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // 1. Watermark-Free, Zero-API-Key Map Tiles
        if (widget.tileStyle == MapTileStyle.darkCyberpunk) ...[
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
            maxZoom: 19,
            maxNativeZoom: 16,
            userAgentPackageName: 'com.example.waypoint_app',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
            maxZoom: 19,
            maxNativeZoom: 16,
            userAgentPackageName: 'com.example.waypoint_app',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
        ] else if (widget.tileStyle == MapTileStyle.satelliteHybrid) ...[
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            maxZoom: 19,
            maxNativeZoom: 18,
            userAgentPackageName: 'com.example.waypoint_app',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
        ] else if (widget.tileStyle == MapTileStyle.streetModern) ...[
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
            maxZoom: 19,
            maxNativeZoom: 18,
            userAgentPackageName: 'com.example.waypoint_app',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
        ] else ...[
          // Default: Classic OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            maxZoom: 19,
            maxNativeZoom: 19,
            userAgentPackageName: 'com.example.waypoint_app',
            retinaMode: RetinaMode.isHighDensity(context),
          ),
        ],

        // 2. Geofence Radius Circle & User Accuracy Ring
        CircleLayer(
          circles: [
            // Target Geofence Area (in meters)
            CircleMarker(
              point: ll.LatLng(target.latitude, target.longitude),
              radius: target.radius,
              useRadiusInMeter: true,
              color: AppTheme.primary.withAlpha(35),
              borderColor: AppTheme.primary,
              borderStrokeWidth: 2.5,
            ),
            // User Location Accuracy Ring & Pulse
            if (userLoc != null) ...[
              CircleMarker(
                point: ll.LatLng(userLoc.latitude, userLoc.longitude),
                radius: (userLoc.accuracy > 0 ? userLoc.accuracy : 15.0).clamp(10.0, 80.0),
                useRadiusInMeter: true,
                color: userRiskColor.withAlpha(30),
                borderColor: userRiskColor.withAlpha(160),
                borderStrokeWidth: 1.5,
              ),
            ],
          ],
        ),

        // 3. Distance Connecting Vector Line
        if (userLoc != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  ll.LatLng(userLoc.latitude, userLoc.longitude),
                  ll.LatLng(target.latitude, target.longitude),
                ],
                strokeWidth: 2.5,
                color: (widget.isInsideGeofence ? AppTheme.safe : AppTheme.primary)
                    .withAlpha(180),
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),

        // 4. Interactive Markers (Unified Marker if at Target, else Separated)
        MarkerLayer(
          markers: [
            if (userLoc != null && (widget.distanceToTarget ?? 999.0) < 30.0)
              // Unified At-Target Checkpoint Marker
              Marker(
                point: ll.LatLng(target.latitude, target.longitude),
                width: 240,
                height: 90,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.safe, width: 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.safe.withAlpha(150),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: AppTheme.safe, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              "${widget.selectedProvince.formattedPlate} ${widget.selectedProvince.name} • SİZ (${widget.riskScore}/100)",
                              style: const TextStyle(
                                color: AppTheme.safe,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.safe.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.safe,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.safe.withAlpha(220),
                                  blurRadius: 14,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.black,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Target Geofence Marker
              Marker(
                point: ll.LatLng(target.latitude, target.longitude),
                width: 180,
                height: 80,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(140),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flag_rounded,
                              color: AppTheme.primary,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              target.name.length > 22
                                  ? "${target.name.substring(0, 20)}..."
                                  : target.name,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primary,
                        size: 36,
                        shadows: [
                          Shadow(color: AppTheme.primary, blurRadius: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Live User GPS Marker (Pulsing High-Tech Beacon)
              if (userLoc != null)
                Marker(
                  point: ll.LatLng(userLoc.latitude, userLoc.longitude),
                  width: 180,
                  height: 85,
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: userRiskColor, width: 1.8),
                            boxShadow: [
                              BoxShadow(
                                color: userRiskColor.withAlpha(120),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: userRiskColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: userRiskColor,
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "📍 SİZ (${widget.riskScore}/100)",
                                style: TextStyle(
                                  color: userRiskColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // High-Tech Glowing Center Pin
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: userRiskColor.withAlpha(60),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: userRiskColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: userRiskColor.withAlpha(220),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}
