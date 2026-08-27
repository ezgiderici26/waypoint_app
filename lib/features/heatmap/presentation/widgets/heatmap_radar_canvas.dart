import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/turkey_provinces.dart';
import '../../domain/entities/heatmap_cluster.dart';
import '../providers/heatmap_providers.dart';

class HeatmapRadarCanvas extends StatefulWidget {
  final List<HeatmapCluster> clusters;
  final HeatmapMode mode;
  final String selectedHub;
  final Function(HeatmapCluster) onClusterTap;

  const HeatmapRadarCanvas({
    super.key,
    required this.clusters,
    required this.mode,
    required this.selectedHub,
    required this.onClusterTap,
  });

  @override
  State<HeatmapRadarCanvas> createState() => _HeatmapRadarCanvasState();
}

class _HeatmapRadarCanvasState extends State<HeatmapRadarCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Dynamic bounding box for 81 provinces and Turkey-wide radar
  double _minLat = 40.9600;
  double _maxLat = 41.1300;
  double _minLon = 28.9500;
  double _maxLon = 29.0600;

  // Center focus offset for smooth panning
  double _centerLat = 41.0200;
  double _centerLon = 29.0050;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _updateFocusForHub(widget.selectedHub);
  }

  @override
  void didUpdateWidget(covariant HeatmapRadarCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedHub != widget.selectedHub) {
      _updateFocusForHub(widget.selectedHub);
    }
  }

  void _updateFocusForHub(String hub) {
    setState(() {
      final matches = TurkeyProvinces.search(hub);
      if (matches.isNotEmpty) {
        final p = matches.first;
        _centerLat = p.latitude;
        _centerLon = p.longitude;
        _minLat = p.latitude - 0.12;
        _maxLat = p.latitude + 0.12;
        _minLon = p.longitude - 0.15;
        _maxLon = p.longitude + 0.15;
        _zoomScale = 1.8;
      } else {
        // Fallback for custom regional districts
        switch (hub) {
          case 'Kadıköy':
            _centerLat = 40.9905;
            _centerLon = 29.0255;
            _minLat = 40.92;
            _maxLat = 41.06;
            _minLon = 28.95;
            _maxLon = 29.10;
            _zoomScale = 1.8;
            break;
          case 'Beşiktaş':
            _centerLat = 41.0428;
            _centerLon = 29.0075;
            _minLat = 40.98;
            _maxLat = 41.10;
            _minLon = 28.94;
            _maxLon = 29.08;
            _zoomScale = 1.8;
            break;
          case 'Taksim':
            _centerLat = 41.0370;
            _centerLon = 28.9850;
            _minLat = 40.97;
            _maxLat = 41.09;
            _minLon = 28.92;
            _maxLon = 29.06;
            _zoomScale = 1.8;
            break;
          case 'Levent':
            _centerLat = 41.0822;
            _centerLon = 29.0125;
            _minLat = 41.02;
            _maxLat = 41.14;
            _minLon = 28.95;
            _maxLon = 29.08;
            _zoomScale = 1.8;
            break;
          case 'Maslak':
            _centerLat = 41.1060;
            _centerLon = 29.0240;
            _minLat = 41.04;
            _maxLat = 41.16;
            _minLon = 28.96;
            _maxLon = 29.09;
            _zoomScale = 1.8;
            break;
          default:
            _centerLat = 39.0000;
            _centerLon = 35.0000;
            _minLat = 35.8000;
            _maxLat = 42.2000;
            _minLon = 25.5000;
            _maxLon = 44.8000;
            _zoomScale = 1.0;
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Offset _latLngToScreen(double lat, double lon, Size size) {
    final double normX = (lon - _minLon) / (_maxLon - _minLon);
    final double normY = 1.0 - ((lat - _minLat) / (_maxLat - _minLat));

    final double centerX = size.width * normX;
    final double centerY = size.height * normY;

    // Apply relative panning to current focus
    final double focusNormX = (_centerLon - _minLon) / (_maxLon - _minLon);
    final double focusNormY =
        1.0 - ((_centerLat - _minLat) / (_maxLat - _minLat));
    final double targetX = size.width * focusNormX;
    final double targetY = size.height * focusNormY;

    final double relX = (centerX - targetX) * _zoomScale + (size.width / 2);
    final double relY = (centerY - targetY) * _zoomScale + (size.height / 2);

    return Offset(relX, relY);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return GestureDetector(
              onTapUp: (details) {
                // Check if tapped near any cluster
                final tapPos = details.localPosition;
                for (final cluster in widget.clusters) {
                  final pos = _latLngToScreen(
                    cluster.latitude,
                    cluster.longitude,
                    size,
                  );
                  final double distance = (tapPos - pos).distance;
                  if (distance < 35.0) {
                    widget.onClusterTap(cluster);
                    return;
                  }
                }
              },
              child: RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: _HeatmapRadarPainter(
                    clusters: widget.clusters,
                    mode: widget.mode,
                    pulseVal: _animController.value,
                    centerLat: _centerLat,
                    centerLon: _centerLon,
                    zoomScale: _zoomScale,
                    selectedHub: widget.selectedHub,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeatmapRadarPainter extends CustomPainter {
  final List<HeatmapCluster> clusters;
  final HeatmapMode mode;
  final double pulseVal;
  final double centerLat;
  final double centerLon;
  final double zoomScale;
  final String selectedHub;

  static const double _minLat = 40.9600;
  static const double _maxLat = 41.1300;
  static const double _minLon = 28.9500;
  static const double _maxLon = 29.0600;

  _HeatmapRadarPainter({
    required this.clusters,
    required this.mode,
    required this.pulseVal,
    required this.centerLat,
    required this.centerLon,
    required this.zoomScale,
    required this.selectedHub,
  });

  Offset _toScreen(double lat, double lon, Size size) {
    final double normX = (lon - _minLon) / (_maxLon - _minLon);
    final double normY = 1.0 - ((lat - _minLat) / (_maxLat - _minLat));

    final double centerX = size.width * normX;
    final double centerY = size.height * normY;

    final double focusNormX = (centerLon - _minLon) / (_maxLon - _minLon);
    final double focusNormY =
        1.0 - ((centerLat - _minLat) / (_maxLat - _minLat));
    final double targetX = size.width * focusNormX;
    final double targetY = size.height * focusNormY;

    final double relX = (centerX - targetX) * zoomScale + (size.width / 2);
    final double relY = (centerY - targetY) * zoomScale + (size.height / 2);

    return Offset(relX, relY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Cyberpunk Radar Background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [const Color(0xFF0F172A), const Color(0xFF070B14)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Tactical Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withAlpha(120)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Coordinate Crosshair in Center
    final centerOffset = Offset(size.width / 2, size.height / 2);
    final crossPaint = Paint()
      ..color = AppTheme.primary.withAlpha(80)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(centerOffset.dx - 20, centerOffset.dy),
      Offset(centerOffset.dx + 20, centerOffset.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(centerOffset.dx, centerOffset.dy - 20),
      Offset(centerOffset.dx, centerOffset.dy + 20),
      crossPaint,
    );

    // Hub Labels watermark
    final hubLocations = {
      'Kadıköy': const [40.9905, 29.0255],
      'Beşiktaş': const [41.0428, 29.0075],
      'Taksim': const [41.0370, 28.9850],
      'Levent': const [41.0822, 29.0125],
      'Maslak': const [41.1060, 29.0240],
    };

    hubLocations.forEach((name, coords) {
      final pos = _toScreen(coords[0], coords[1], size);
      final isSelected = selectedHub == name;

      final textSpan = TextSpan(
        text: "📍 $name",
        style: TextStyle(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.textSecondary.withAlpha(150),
          fontSize: isSelected ? 12 : 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - (textPainter.width / 2), pos.dy + 18),
      );
    });

    // 4. Draw Heatmap Clusters as Multi-Layer Radial Gradient Circles
    for (final cluster in clusters) {
      final pos = _toScreen(cluster.latitude, cluster.longitude, size);

      Color baseColor;
      if (mode == HeatmapMode.density) {
        if (cluster.count >= 6) {
          baseColor = const Color(0xFFFF3344); // Critical Fire
        } else if (cluster.count >= 4) {
          baseColor = const Color(0xFFFF9900); // Orange
        } else if (cluster.count >= 2) {
          baseColor = const Color(0xFF00FF88); // Green
        } else {
          baseColor = const Color(0xFF00CCFF); // Blue
        }
      } else if (mode == HeatmapMode.risk) {
        if (cluster.hasHighRisk) {
          baseColor = AppTheme.spoofed; // Threat Red
        } else if (cluster.averageRiskScore >= 35) {
          baseColor = AppTheme.suspicious; // Orange
        } else {
          baseColor = AppTheme.safe; // Safe Green
        }
      } else {
        baseColor = AppTheme.primary;
      }

      final double baseRadius =
          (20.0 + (cluster.count * 3.5)) * zoomScale * 0.7;
      final double pulsatingRadius = baseRadius * (1.0 + (pulseVal * 0.18));

      // Layer 1: Outer Soft Halo
      final haloPaint = Paint()
        ..color = baseColor.withAlpha(45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(pos, pulsatingRadius * 1.5, haloPaint);

      // Layer 2: Radiant Heat Gradient Ring
      final ringGradient = RadialGradient(
        colors: [
          baseColor.withAlpha(180),
          baseColor.withAlpha(60),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      );
      final ringPaint = Paint()
        ..shader = ringGradient.createShader(
          Rect.fromCircle(center: pos, radius: pulsatingRadius),
        );
      canvas.drawCircle(pos, pulsatingRadius, ringPaint);

      // Layer 3: Solid Inner Core
      final corePaint = Paint()..color = baseColor;
      canvas.drawCircle(pos, 6.0 * zoomScale * 0.7, corePaint);

      final coreBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(pos, 6.0 * zoomScale * 0.7, coreBorder);

      // Badge Number Text
      final countText = TextSpan(
        text: "${cluster.count}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      );
      final countPainter = TextPainter(
        text: countText,
        textDirection: TextDirection.ltr,
      )..layout();
      countPainter.paint(
        canvas,
        Offset(
          pos.dx - (countPainter.width / 2),
          pos.dy - (countPainter.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapRadarPainter oldDelegate) {
    return oldDelegate.pulseVal != pulseVal ||
        oldDelegate.centerLat != centerLat ||
        oldDelegate.centerLon != centerLon ||
        oldDelegate.mode != mode ||
        oldDelegate.clusters != clusters ||
        oldDelegate.selectedHub != selectedHub;
  }
}
