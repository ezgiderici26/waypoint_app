import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/heatmap_cluster.dart';

class HeatmapPointDetailDialog extends ConsumerWidget {
  final HeatmapCluster cluster;

  const HeatmapPointDetailDialog({super.key, required this.cluster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasRisk = cluster.hasHighRisk;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF2A3547), width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with target name and risk badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cluster.primaryTargetName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${cluster.latitude.toStringAsFixed(4)}, ${cluster.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (hasRisk ? AppTheme.spoofed : AppTheme.safe)
                        .withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasRisk ? AppTheme.spoofed : AppTheme.safe,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRisk
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                        color: hasRisk ? AppTheme.spoofed : AppTheme.safe,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Ort. Risk: ${cluster.averageRiskScore.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: hasRisk ? AppTheme.spoofed : AppTheme.safe,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Pills
            Row(
              children: [
                _buildCountBadge("Toplam: ${cluster.count}", AppTheme.primary),
                const SizedBox(width: 8),
                _buildCountBadge(
                  "Güvenli: ${cluster.safeCount}",
                  AppTheme.safe,
                ),
                const SizedBox(width: 8),
                if (cluster.blockedCount > 0)
                  _buildCountBadge(
                    "Engellenen: ${cluster.blockedCount}",
                    AppTheme.spoofed,
                  ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFF2A3547)),

            const Text(
              "KÜME İÇİ CHECK-IN LOGLARI",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Records List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cluster.records.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final rec = cluster.records[index];
                  final bool isRisky = rec.isBlocked || rec.riskScore >= 35;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRisky
                            ? AppTheme.spoofed.withAlpha(100)
                            : const Color(0xFF2A3547),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  rec.isBlocked
                                      ? Icons.block_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: rec.isBlocked
                                      ? AppTheme.spoofed
                                      : AppTheme.safe,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  rec.isBlocked
                                      ? "Engellendi"
                                      : "Başarılı Check-in",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: rec.isBlocked
                                        ? AppTheme.spoofed
                                        : AppTheme.safe,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Risk: ${rec.riskScore}/100",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: rec.riskScore < 35
                                    ? AppTheme.safe
                                    : (rec.riskScore < 70
                                          ? AppTheme.suspicious
                                          : AppTheme.spoofed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Cihaz: ${rec.deviceStatus}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tarih: ${rec.timestamp.split('T').first} ${rec.timestamp.contains('T') ? rec.timestamp.split('T')[1].substring(0, 5) : ''}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              rec.isSynced
                                  ? "Sunucuya Eşitlendi ✓"
                                  : "Kuyrukta (Offline) ⏳",
                              style: TextStyle(
                                fontSize: 10,
                                color: rec.isSynced
                                    ? AppTheme.safe
                                    : AppTheme.suspicious,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
