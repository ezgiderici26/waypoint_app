import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../check_in/presentation/providers/check_in_providers.dart';
import '../providers/heatmap_providers.dart';

class HeatmapStatsSheet extends ConsumerWidget {
  const HeatmapStatsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(heatmapStatsProvider);
    final state = ref.watch(heatmapNotifierProvider);
    final notifier = ref.read(heatmapNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF2A3547), width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
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

              // Title and close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "YÖNETİCİ ISI & ANALİTİK",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 Core KPI Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: "Toplam Kayıt",
                      value: "${stats.totalRecords}",
                      icon: Icons.pin_drop_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: "Güvenlik Oranı",
                      value: "%${stats.safePercentage.toStringAsFixed(0)}",
                      icon: Icons.verified_user_rounded,
                      color: AppTheme.safe,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: "Tehdit / Engelli",
                      value: "${stats.riskyOrBlockedRecords}",
                      icon: Icons.gpp_bad_rounded,
                      color: AppTheme.spoofed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: "Ort. Risk Skoru",
                      value: "${stats.averageRiskScore.toStringAsFixed(0)}/100",
                      icon: Icons.speed_rounded,
                      color: stats.averageRiskScore < 35
                          ? AppTheme.safe
                          : (stats.averageRiskScore < 70
                                ? AppTheme.suspicious
                                : AppTheme.spoofed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hotspot & Threat Breakdown Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A3547)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.whatshot_rounded,
                              color: Color(0xFFFF9900),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "En Yoğun Hotspot:",
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${stats.topHotspotName} (${stats.topHotspotCount} Adet)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: Color(0xFF2A3547)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.vpn_lock_rounded,
                              color: AppTheme.suspicious,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Mock GPS / VPN İhlalleri:",
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${stats.vpnOrMockDetections} Olay Yakalandı",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.spoofed,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Radius & Intensity Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Isı Yarıçapı & Yayılım Çarpanı",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    "${(state.radiusMultiplier * 100).toInt()}%",
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: state.radiusMultiplier,
                min: 0.5,
                max: 2.5,
                divisions: 8,
                activeColor: AppTheme.primary,
                inactiveColor: const Color(0xFF2A3547),
                onChanged: (val) => notifier.setRadiusMultiplier(val),
              ),
              const SizedBox(height: 16),

              // Seed and Clear Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.science_rounded, size: 18),
                      label: const Text(
                        "Demo Küme Ekle",
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await notifier.seedHeatmapDemoData(ref);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "İstanbul geneli 22 adet demo check-in kümesi yüklendi!",
                              ),
                              backgroundColor: AppTheme.safe,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      size: 18,
                      color: AppTheme.spoofed,
                    ),
                    label: const Text(
                      "Temizle",
                      style: TextStyle(fontSize: 13, color: AppTheme.spoofed),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.spoofed),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    onPressed: () async {
                      await ref
                          .read(checkInHistoryProvider.notifier)
                          .clearAllRecords();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Tüm check-in veritabanı temizlendi.",
                            ),
                            backgroundColor: AppTheme.spoofed,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3547)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
