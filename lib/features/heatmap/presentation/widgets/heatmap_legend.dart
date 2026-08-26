import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/heatmap_providers.dart';

class HeatmapLegend extends StatelessWidget {
  final HeatmapMode mode;

  const HeatmapLegend({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3547)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mode == HeatmapMode.density
                ? "YOĞUNLUK SKALASI"
                : (mode == HeatmapMode.risk ? "GÜVENLİK RİSKİ" : "NOKTASAL"),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (mode == HeatmapMode.density) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem(const Color(0xFF00D2FF), "Düşük (1)"),
                const SizedBox(width: 8),
                _buildLegendItem(const Color(0xFF10B981), "Orta (2-3)"),
                const SizedBox(width: 8),
                _buildLegendItem(const Color(0xFFFF9900), "Yüksek (4-5)"),
                const SizedBox(width: 8),
                _buildLegendItem(const Color(0xFFFF3366), "Kritik (6+)"),
              ],
            ),
          ] else if (mode == HeatmapMode.risk) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem(AppTheme.safe, "Güvenli (<35)"),
                const SizedBox(width: 10),
                _buildLegendItem(AppTheme.suspicious, "Şüpheli (35-69)"),
                const SizedBox(width: 10),
                _buildLegendItem(AppTheme.spoofed, "Tehdit (70+)"),
              ],
            ),
          ] else ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem(AppTheme.primary, "Check-in Noktaları"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withAlpha(180), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
