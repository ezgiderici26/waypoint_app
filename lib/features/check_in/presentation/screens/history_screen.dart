import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/check_in_record.dart';
import '../providers/check_in_providers.dart';

import '../../../heatmap/presentation/screens/admin_heatmap_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  // ──────────────────────────────────────────────────────────
  // CSV Dışa Aktarma
  // ──────────────────────────────────────────────────────────
  String _buildCsv(List<CheckInRecord> logs) {
    final header =
        'id,timestamp,plateCode,targetName,latitude,longitude,accuracy,riskScore,deviceStatus,isSynced,isBlocked';
    final rows = logs
        .map((r) {
          String esc(String v) => v.contains(',') ? '"$v"' : v;
          return [
            r.id,
            r.timestamp,
            r.plateCode?.toString() ?? '',
            esc(r.targetName),
            r.latitude.toStringAsFixed(7),
            r.longitude.toStringAsFixed(7),
            r.accuracy.toStringAsFixed(2),
            r.riskScore.toString(),
            esc(r.deviceStatus),
            r.isSynced ? '1' : '0',
            r.isBlocked ? '1' : '0',
          ].join(',');
        })
        .join('\n');
    return '$header\n$rows';
  }

  // ──────────────────────────────────────────────────────────
  // JSON Dışa Aktarma
  // ──────────────────────────────────────────────────────────
  String _buildJson(List<CheckInRecord> logs) {
    final payload = {
      'app': 'WaypointApp',
      'exportedAt': DateTime.now().toIso8601String(),
      'totalRecords': logs.length,
      'records': logs.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // ──────────────────────────────────────────────────────────
  // Dışa Aktarma Modal Sheet
  // ──────────────────────────────────────────────────────────
  void _showExportSheet(BuildContext context, List<CheckInRecord> logs) {
    final safeCount = logs
        .where((r) => !r.isBlocked && r.riskScore < 35)
        .length;
    final blockedCount = logs.where((r) => r.isBlocked).length;
    final syncedCount = logs.where((r) => r.isSynced).length;
    final avgRisk = logs.isEmpty
        ? 0.0
        : logs.map((r) => r.riskScore).reduce((a, b) => a + b) / logs.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A3547), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            // Başlık
            const Row(
              children: [
                Icon(Icons.download_rounded, color: AppTheme.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'RAPOR DIŞA AKTARMA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // İstatistik özeti
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withAlpha(60)),
              ),
              child: Column(
                children: [
                  _StatRow(
                    'Toplam Kayıt',
                    '${logs.length}',
                    AppTheme.textPrimary,
                  ),
                  _StatRow('Güvenli Check-in', '$safeCount', AppTheme.safe),
                  _StatRow('Engellenen', '$blockedCount', AppTheme.spoofed),
                  _StatRow('Senkronize', '$syncedCount', AppTheme.primary),
                  _StatRow(
                    'Ort. Risk Skoru',
                    avgRisk.toStringAsFixed(1),
                    AppTheme.suspicious,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // CSV Butonu
            _ExportButton(
              icon: Icons.table_chart_rounded,
              label: 'CSV Olarak Kopyala',
              subtitle: 'Excel / Google Sheets uyumlu',
              color: AppTheme.safe,
              onTap: () async {
                final csv = _buildCsv(logs);
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ ${logs.length} kayıt CSV formatında kopyalandı. Excel\'e yapıştırabilirsiniz.',
                      ),
                      backgroundColor: AppTheme.safe,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            // JSON Butonu
            _ExportButton(
              icon: Icons.data_object_rounded,
              label: 'JSON Olarak Kopyala',
              subtitle: 'API / Mock Sunucu payload formatı',
              color: AppTheme.primary,
              onTap: () async {
                final json = _buildJson(logs);
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ ${logs.length} kayıt JSON formatında kopyalandı.',
                      ),
                      backgroundColor: AppTheme.primary,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch history logs from Hive provider
    final logs = ref.watch(checkInHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("GEÇMİŞ KAYITLAR"),
        actions: [
          // Dışa Aktarma Butonu
          if (logs.isNotEmpty)
            IconButton(
              tooltip: 'Dışa Aktar (CSV / JSON)',
              icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
              onPressed: () => _showExportSheet(context, logs),
            ),
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
              final success = await ref
                  .read(checkInHistoryProvider.notifier)
                  .syncPendingRecords();
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
          : Column(
              children: [
                // Top AES-256 Encryption Status Banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withAlpha(80)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.enhanced_encryption_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "AES-256 CBC Şifreli Yerel Depolama",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              "Hive DB üzerindeki tüm kayıtlar & donanım imzaları şifrelenmiştir.",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary.withAlpha(190),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.safe.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.safe, width: 0.8),
                        ),
                        child: const Text(
                          "KORUMALI",
                          style: TextStyle(
                            color: AppTheme.safe,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
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
                        formattedTime =
                            "${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
                      } catch (_) {}

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Plaka kodu rozeti (varsa)
                                  if (log.plateCode != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withAlpha(28),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.primary.withAlpha(
                                            120,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        '📍 ${log.plateCode}',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(26),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor,
                                        width: 1,
                                      ),
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
                              const Divider(
                                height: 20,
                                color: Color(0xFF2A3547),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Risk Skoru: $risk/100",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: risk >= 35
                                          ? AppTheme.spoofed
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        log.isSynced
                                            ? Icons.cloud_done_rounded
                                            : Icons.cloud_off_rounded,
                                        size: 16,
                                        color: log.isSynced
                                            ? AppTheme.primary
                                            : AppTheme.suspicious,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        log.isSynced
                                            ? "Sunucuyla Eşleşti"
                                            : "Kuyrukta Bekliyor",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: log.isSynced
                                              ? AppTheme.primary
                                              : AppTheme.suspicious,
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
                ),
              ],
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Yardımcı Widget: İstatistik Satırı
// ──────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Yardımcı Widget: Dışa Aktarma Butonu
// ──────────────────────────────────────────────────────────
class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, color: color.withAlpha(150), size: 18),
          ],
        ),
      ),
    );
  }
}
