import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../location_map/presentation/providers/antispoofing_providers.dart';
import '../providers/security_providers.dart';

class SecurityDashboardScreen extends ConsumerWidget {
  const SecurityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(securityProvider);
    final riskState = ref.watch(antispoofingProvider);
    final int riskScore = riskState.riskScore;

    // Determine security color based on risk score
    Color scoreColor = AppTheme.safe;
    String securityMsg = "Cihaz ortamı güvenli kabul ediliyor.";
    if (riskScore >= 70) {
      scoreColor = AppTheme.spoofed;
      securityMsg = "Yüksek güvenlik ihlali algılandı! Sistem kilitlendi.";
    } else if (riskScore >= 35) {
      scoreColor = AppTheme.suspicious;
      securityMsg = "Cihazda şüpheli aktiviteler algılandı.";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("CİHAZ VE GÜVENLİK"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(securityProvider.notifier).checkIntegrity();
            },
          ),
        ],
      ),
      body: securityState.isChecking
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Device Security Card with visual meter
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Glowing Safety Shield Icon
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: scoreColor.withAlpha(26),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scoreColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scoreColor.withAlpha(51),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  riskScore < 35
                                      ? Icons.verified_user_rounded
                                      : (riskScore < 70
                                            ? Icons.gpp_maybe_rounded
                                            : Icons.gpp_bad_rounded),
                                  size: 36,
                                  color: scoreColor,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Güvenlik Durumu",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      securityMsg,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Linear progress indicator visual representation of risk
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Genel Cihaz Risk Skoru",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          "$riskScore/100",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: scoreColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: riskScore / 100,
                                        backgroundColor: const Color(
                                          0xFF2A3547,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              scoreColor,
                                            ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "BÜTÜNLÜK KONTROLLERİ (INTEGRITY)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Specific Security Check Rows
                  _buildSecurityRow(
                    icon: Icons.adb_rounded,
                    title: "Geliştirici Modu / USB Ayıklama",
                    statusText: securityState.isDeveloperMode
                        ? "Etkin (Riskli)"
                        : "Kapalı",
                    isFailure: securityState.isDeveloperMode,
                    description:
                        "Aktif geliştirici modu, üçüncü parti uygulamaların konumu manipüle etmesini kolaylaştırır.",
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityRow(
                    icon: Icons.no_encryption_gmailerrorred_rounded,
                    title: "Root / Jailbreak Tespiti",
                    statusText: securityState.isJailbroken
                        ? "Root Edilmiş"
                        : "Güvenli (Root Yok)",
                    isFailure: securityState.isJailbroken,
                    description:
                        "Köklü erişim, sistem düzeyinde konum kütüphanelerinin manipüle edilmesini sağlar.",
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityRow(
                    icon: Icons.devices_rounded,
                    title: "Emülatör Tespiti",
                    statusText: securityState.isEmulator
                        ? "Emülatör Algılandı"
                        : "Fiziksel Cihaz",
                    isFailure: securityState.isEmulator,
                    description:
                        "Uygulamanın sanal cihazlar yerine sadece fiziksel cihazlarda çalışması istenir.",
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityRow(
                    icon: Icons.vpn_lock_rounded,
                    title: "VPN & Proxy Filtresi",
                    statusText: securityState.isVpnActive
                        ? "Aktif (tun0/ppp0)"
                        : "Bağlantı Yok",
                    isFailure: securityState.isVpnActive,
                    description:
                        "VPN tünelleri ve proxy sunucuları ağ trafiğini ve IP tabanlı konumları şaşırtabilir.",
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityRow(
                    icon: Icons.shield_rounded,
                    title: "Play Integrity / App Attest",
                    statusText: securityState.isIntegrityVerified
                        ? "Doğrulandı"
                        : "Bütünlük İhlali",
                    isFailure: !securityState.isIntegrityVerified,
                    description:
                        "Karar: ${securityState.integrityVerdict}. Cihazın modifiye edilmediğini sunucu taraflı platform imzasıyla kriptografik doğrular.",
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityRow({
    required IconData icon,
    required String title,
    required String statusText,
    required bool isFailure,
    required String description,
  }) {
    final statusColor = isFailure ? AppTheme.suspicious : AppTheme.safe;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
