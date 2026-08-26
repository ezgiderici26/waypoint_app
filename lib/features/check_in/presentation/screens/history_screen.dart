import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/check_in_providers.dart';

import '../../../heatmap/presentation/screens/admin_heatmap_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch history logs from Hive provider
    final logs = ref.watch(checkInHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("GEÇMİŞ KAYITLAR"),
        actions: [
          IconButton(
            tooltip: "Isı Haritası",
            icon: const Icon(Icons.whatshot_rounded, color: AppTheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminHeatmapScreen()),
              );
            },
          ),
          IconButton(
            tooltip: "Senkronize Et",
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Senkronizasyon kuyruğu çalıştırılıyor..."),
                  duration: Duration(seconds: 1),
                ),
              );
              final success = await ref.read(checkInHistoryProvider.notifier).syncPendingRecords();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? "Kuyruk başarıyla sunucuyla eşitlendi!" 
                          : "Ağ Hatası: Bazı kayıtlar eşitlenemedi, kuyrukta bekletiliyor.",
                    ),
                    backgroundColor: success ? AppTheme.safe : AppTheme.spoofed,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 64,
                    color: AppTheme.textSecondary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Henüz check-in kaydı bulunmuyor.",
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final int risk = log.riskScore;
                
                Color statusColor;
                String statusText;
                if (log.isBlocked) {
                  statusColor = AppTheme.spoofed;
                  statusText = "ENGELLENDİ";
                } else if (risk < 35) {
                  statusColor = AppTheme.safe;
                  statusText = "GÜVENLİ";
                } else if (risk < 70) {
                  statusColor = AppTheme.suspicious;
                  statusText = "ŞÜPHELİ";
                } else {
                  statusColor = AppTheme.spoofed;
                  statusText = "REDDEDİLDİ";
                }

                // Format timestamp beautifully (simple slice of ISO string)
                String formattedTime = log.timestamp;
                try {
                  final parsed = DateTime.parse(log.timestamp);
                  formattedTime = "${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
                } catch (_) {}

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                log.targetName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor, width: 1),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Koordinat: ${log.latitude.toStringAsFixed(5)}, ${log.longitude.toStringAsFixed(5)}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Zaman: $formattedTime",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (log.deviceStatus.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Güvenlik: ${log.deviceStatus}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const Divider(height: 20, color: Color(0xFF2A3547)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Risk Skoru: $risk/100",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: risk >= 35 ? AppTheme.spoofed : AppTheme.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  log.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                  size: 16,
                                  color: log.isSynced ? AppTheme.primary : AppTheme.suspicious,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  log.isSynced ? "Sunucuyla Eşleşti" : "Kuyrukta Bekliyor",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: log.isSynced ? AppTheme.primary : AppTheme.suspicious,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
