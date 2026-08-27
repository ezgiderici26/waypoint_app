import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/turkey_provinces.dart';
import '../../domain/entities/location_data.dart';
import '../providers/location_providers.dart';

class MainRadarCanvas extends StatefulWidget {
  final LocationData? userLocation;
  final TargetLocation targetLocation;
  final TurkeyProvince selectedProvince;
  final int riskScore;
  final bool isInsideGeofence;
  final double? distanceToTarget;
  final VoidCallback? onOpenCitySelector;

  const MainRadarCanvas({
    super.key,
    required this.userLocation,
    required this.targetLocation,
    required this.selectedProvince,
    required this.riskScore,
    required this.isInsideGeofence,
    required this.distanceToTarget,
    this.onOpenCitySelector,
  });

  @override
  State<MainRadarCanvas> createState() => _MainRadarCanvasState();
}

class _MainRadarCanvasState extends State<MainRadarCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _zoom = 1.0; // Zoom multiplier: 0.5x to 4.0x

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom * 1.3).clamp(0.4, 6.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom / 1.3).clamp(0.4, 6.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoom = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasUser = widget.userLocation != null;
    final userLat = widget.userLocation?.latitude;
    final userLng = widget.userLocation?.longitude;

    return Container(
      color: const Color(0xFF070B14),
      child: Stack(
        children: [
          // 1. Custom Painted Tactical Radar Background & Objects
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: _MainRadarPainter(
                      sweepAngle: _animController.value * 2 * pi,
                      userLat: userLat,
                      userLng: userLng,
                      targetLat: widget.targetLocation.latitude,
                      targetLng: widget.targetLocation.longitude,
                      targetRadius: widget.targetLocation.radius,
                      targetName: widget.targetLocation.name,
                      riskScore: widget.riskScore,
                      isInsideGeofence: widget.isInsideGeofence,
                      distanceMeters: widget.distanceToTarget,
                      zoom: _zoom,
                      provinceName: widget.selectedProvince.name,
                      plateCode: widget.selectedProvince.formattedPlate,
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Top Banner (Radar Mode Status)
          Positioned(
            top: 76,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withAlpha(230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withAlpha(120),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(40),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "TAKTIK RADAR: ${widget.selectedProvince.formattedPlate} ${widget.selectedProvince.name.toUpperCase()} (API'sız Canlı GPS)",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppTheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onOpenCitySelector != null)
                    InkWell(
                      onTap: widget.onOpenCitySelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(100),
                          ),
                        ),
                        child: const Text(
                          "İl Değiştir",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Zoom Controls on Top Right
          Positioned(
            right: 16,
            top: 135,
            child: Column(
              children: [
                _buildRadarButton(
                  icon: Icons.add_rounded,
                  tooltip: "Yakınlaştır",
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _buildRadarButton(
                  icon: Icons.remove_rounded,
                  tooltip: "Uzaklaştır",
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 8),
                _buildRadarButton(
                  icon: Icons.center_focus_strong_rounded,
                  tooltip: "Sıfırla",
                  onTap: _resetZoom,
                ),
              ],
            ),
          ),

          // 4. GPS Searching indicator if user location is not yet available
          if (!hasUser)
            Positioned(
              top: 135,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.suspicious.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.suspicious.withAlpha(120)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.suspicious,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "GPS Kilitleniyor...",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.suspicious,
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

  Widget _buildRadarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withAlpha(220),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A3547)),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
      ),
    );
  }
}

class _MainRadarPainter extends CustomPainter {
  final double sweepAngle;
  final double? userLat;
  final double? userLng;
  final double targetLat;
  final double targetLng;
  final double targetRadius;
  final String targetName;
  final int riskScore;
  final bool isInsideGeofence;
  final double? distanceMeters;
  final double zoom;
  final String provinceName;
  final String plateCode;

  _MainRadarPainter({
    required this.sweepAngle,
    required this.userLat,
    required this.userLng,
    required this.targetLat,
    required this.targetLng,
    required this.targetRadius,
    required this.targetName,
    required this.riskScore,
    required this.isInsideGeofence,
    required this.distanceMeters,
    required this.zoom,
    required this.provinceName,
    required this.plateCode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final maxRadius = min(size.width, size.height) * 0.42;

    // 1. Draw Grid Background (Concentric Circles & Radial Spokes)
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rings = [0.25, 0.50, 0.75, 1.0];
    for (final r in rings) {
      canvas.drawCircle(center, maxRadius * r, gridPaint);
    }

    // Radial Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final spokeEnd = Offset(
        center.dx + maxRadius * cos(angle),
        center.dy + maxRadius * sin(angle),
      );
      canvas.drawLine(center, spokeEnd, spokePaint);
    }

    // Cardinal Labels (KUZEY, DOĞU, GÜNEY, BATI)
    _drawText(canvas, "K", Offset(center.dx, center.dy - maxRadius - 14), AppTheme.primary);
    _drawText(canvas, "G", Offset(center.dx, center.dy + maxRadius + 4), AppTheme.textSecondary);
    _drawText(canvas, "D", Offset(center.dx + maxRadius + 10, center.dy - 6), AppTheme.textSecondary);
    _drawText(canvas, "B", Offset(center.dx - maxRadius - 18, center.dy - 6), AppTheme.textSecondary);

    // 2. Rotating Radar Sweep Effect
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset(center.dx / size.width, center.dy / size.height),
        startAngle: 0.0,
        endAngle: pi / 2,
        colors: [
          const Color(0xFF00E5FF).withAlpha(90),
          const Color(0xFF00E5FF).withAlpha(0),
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: maxRadius)),
    );
    canvas.drawCircle(center, maxRadius, sweepPaint);
    canvas.restore();

    // 3. Coordinate Scaling Logic
    // Scale: meters to pixels
    // Let 1.0 ring = 500m / zoom
    final double meterScale = (maxRadius / 500.0) * zoom;

    // Center is target point
    final targetCenter = center;

    // Draw Target Geofence Zone
    final geofencePixelRadius = max(18.0, targetRadius * meterScale);
    final geofenceFillPaint = Paint()
      ..color = AppTheme.primary.withAlpha(35)
      ..style = PaintingStyle.fill;
    final geofenceStrokePaint = Paint()
      ..color = AppTheme.primary.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(targetCenter, geofencePixelRadius, geofenceFillPaint);
    canvas.drawCircle(targetCenter, geofencePixelRadius, geofenceStrokePaint);

    // Target Beacon Icon
    final targetDotPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 7, targetDotPaint);
    _drawText(
      canvas,
      "🎯 HEDEF: $targetName",
      Offset(targetCenter.dx, targetCenter.dy + geofencePixelRadius + 4),
      AppTheme.primary,
      isBold: true,
      fontSize: 10,
    );

    // 4. Draw User Location Node if available
    if (userLat != null && userLng != null) {
      // Calculate delta meters from target (lat / lng meters approx: 1 deg lat = 111,000m)
      const latMeters = 111000.0;
      final lngMeters = 111000.0 * cos(targetLat * pi / 180.0);

      final dyMeters = (userLat! - targetLat) * latMeters;
      final dxMeters = (userLng! - targetLng) * lngMeters;

      // Invert Y because canvas Y increases downwards, whereas Latitude increases upwards (North)
      final userOffset = Offset(
        targetCenter.dx + (dxMeters * meterScale),
        targetCenter.dy - (dyMeters * meterScale),
      );

      // Connect User and Target with Vector Line
      final linePaint = Paint()
        ..color = (isInsideGeofence ? AppTheme.safe : AppTheme.secondary).withAlpha(160)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(targetCenter, userOffset, linePaint);

      // Distance tag midway
      final midPoint = Offset(
        (targetCenter.dx + userOffset.dx) / 2,
        (targetCenter.dy + userOffset.dy) / 2,
      );
      if (distanceMeters != null) {
        final distStr = distanceMeters! < 1000
            ? "${distanceMeters!.round()} m"
            : "${(distanceMeters! / 1000).toStringAsFixed(2)} km";
        _drawBadge(canvas, distStr, midPoint);
      }

      // User Dot Color based on risk
      final Color userColor = riskScore < 35
          ? AppTheme.safe
          : (riskScore < 70 ? AppTheme.suspicious : AppTheme.spoofed);

      // Pulsating aura
      final auraPaint = Paint()
        ..color = userColor.withAlpha(60)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(userOffset, 16, auraPaint);

      final userDotPaint = Paint()
        ..color = userColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(userOffset, 8, userDotPaint);

      final userBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(userOffset, 8, userBorderPaint);

      _drawText(
        canvas,
        "📍 SİZ ($riskScore/100)",
        Offset(userOffset.dx, userOffset.dy - 22),
        userColor,
        isBold: true,
        fontSize: 11,
      );
    }

    // 5. Radar Scale Legend at bottom left
    final double radiusInMeters = 500.0 / zoom;
    final scaleText = radiusInMeters >= 1000
        ? "Radar Ölçeği: ${(radiusInMeters / 1000).toStringAsFixed(1)} km"
        : "Radar Ölçeği: ${radiusInMeters.round()} m";
    _drawText(
      canvas,
      scaleText,
      Offset(24, size.height * 0.88),
      AppTheme.textSecondary,
      fontSize: 11,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color, {
    bool isBold = false,
    double fontSize = 12,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      position.dx - (textPainter.width / 2),
      position.dy - (textPainter.height / 2),
    );
    textPainter.paint(canvas, offset);
  }

  void _drawBadge(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      ),
      const Radius.circular(6),
    );

    final bgPaint = Paint()..color = const Color(0xFF0F172A).withAlpha(220);
    final borderPaint = Paint()
      ..color = AppTheme.primary.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(badgeRect, bgPaint);
    canvas.drawRRect(badgeRect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MainRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.userLat != userLat ||
        oldDelegate.userLng != userLng ||
        oldDelegate.targetLat != targetLat ||
        oldDelegate.targetLng != targetLng ||
        oldDelegate.targetRadius != targetRadius ||
        oldDelegate.zoom != zoom ||
        oldDelegate.riskScore != riskScore ||
        oldDelegate.distanceMeters != distanceMeters;
  }
}
