import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/risk_tuning_config.dart';
import '../providers/risk_tuning_providers.dart';

class RiskTuningScreen extends ConsumerWidget {
  const RiskTuningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuning = ref.watch(riskTuningProvider);
    final tuningNotifier = ref.read(riskTuningProvider.notifier);
    final sandboxFlags = ref.watch(sandboxFlagsProvider);
    final sandboxNotifier = ref.read(sandboxFlagsProvider.notifier);
    final sandboxScore = ref.watch(sandboxScoreProvider);
    final sandboxCategory = tuning.getCategory(sandboxScore);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Dinamik Risk Tuning & Kalibrasyon",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: AppTheme.primary,
            ),
            tooltip: "Varsayılanlara Sıfırla",
            onPressed: () {
              tuningNotifier.resetToDefaults();
              sandboxNotifier.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Risk katsayıları varsayılan 'Dengeli' profile sıfırlandı.",
                  ),
                  backgroundColor: AppTheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Preset Profiles Segmented Selector
          _buildPresetSelector(context, tuning.profileKey, tuningNotifier),

          const SizedBox(height: 16),

          // 2. Interactive Live Calibration Sandbox Card
          _buildLiveSandboxCard(
            context,
            tuning,
            sandboxFlags,
            sandboxNotifier,
            sandboxScore,
            sandboxCategory,
          ),

          const SizedBox(height: 24),

          // 3. Section Title: K1-K7 Coefficients
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "KATSAYI AĞIRLIKLARI (K1 - K7)",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // K1 Slider
          _buildCoefficientSlider(
            title: "K1: OS Mock Provider Flag",
            subtitle: "İşletim sistemi sahte konum bayrağı (Android/iOS)",
            icon: Icons.gpp_bad_rounded,
            color: Colors.redAccent,
            value: tuning.k1OsMock,
            onChanged: (val) => tuningNotifier.updateK1(val.toInt()),
          ),

          const SizedBox(height: 10),

          // K2 Slider
          _buildCoefficientSlider(
            title: "K2: Mock GPS Uygulama Paketi",
            subtitle: "Mock provider veya Fake GPS paketi tespiti",
            icon: Icons.apps_outage_rounded,
            color: Colors.deepOrangeAccent,
            value: tuning.k2MockApp,
            onChanged: (val) => tuningNotifier.updateK2(val.toInt()),
          ),

          const SizedBox(height: 10),

          // K3 Slider
          _buildCoefficientSlider(
            title: "K3: Geliştirici Modu & USB Debugging",
            subtitle: "Cihazda ADB / Developer Options aktifliği",
            icon: Icons.developer_mode_rounded,
            color: Colors.amber,
            value: tuning.k3DevMode,
            onChanged: (val) => tuningNotifier.updateK3(val.toInt()),
          ),

          const SizedBox(height: 10),

          // K4 Slider
          _buildCoefficientSlider(
            title: "K4: İmkânsız Hız / Işınlanma (> 150 km/h)",
            subtitle: "Ardışık GPS sıçramaları ve telekinezi tespiti",
            icon: Icons.speed_rounded,
            color: Colors.purpleAccent,
            value: tuning.k4Speed,
            onChanged: (val) => tuningNotifier.updateK4(val.toInt()),
          ),

          const SizedBox(height: 10),

          // K5 Slider
          _buildCoefficientSlider(
            title: "K5: İvmeölçer Sensör Tutarsızlığı",
            subtitle: "Fiziksel ivmeölçer vs GPS hız değişimi karşılaştırması",
            icon: Icons.sensors_off_rounded,
            color: Colors.cyanAccent,
            value: tuning.k5Sensor,
            onChanged: (val) => tuningNotifier.updateK5(val.toInt()),
          ),

          const SizedBox(height: 10),

          // K6 Slider
          _buildCoefficientSlider(
            title: "K6: Cihaz Bütünlüğü (Root / Emulator)",
            subtitle: "Rootlu cihaz veya sanal emülatör ortamı",
            icon: Icons.security_rounded,
            color: Colors.orangeAccent,
            value: tuning.k6Integrity,
            onChanged: (val) => tuningNotifier.updateK6(val.toInt()),
          ),

          const SizedBox(height: 10),

          // K7 Slider
          _buildCoefficientSlider(
            title: "K7: Ağ Güvenliği (VPN / Proxy Tüneli)",
            subtitle: "tun0/ppp0 sanal ağ arayüzü tespiti",
            icon: Icons.vpn_lock_rounded,
            color: Colors.blueAccent,
            value: tuning.k7Vpn,
            onChanged: (val) => tuningNotifier.updateK7(val.toInt()),
          ),

          const SizedBox(height: 24),

          // 4. Threshold Section
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "GÜVENLİK EŞİK SINIRLARI",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildThresholdCard(
            title: "🟢 Güvenli Eşik Limiti (Safe Max)",
            subtitle:
                "Bu puanın altındaki check-in'ler güvenli kabul edilir ve izin verilir.",
            value: tuning.safeThreshold,
            min: 10,
            max: 50,
            color: AppTheme.safe,
            onChanged: (val) => tuningNotifier.updateSafeThreshold(val.toInt()),
          ),

          const SizedBox(height: 10),

          _buildThresholdCard(
            title: "🟡 Şüpheli Eşik Limiti (Suspicious Max)",
            subtitle:
                "Bu puanın üzerindeki tüm işlemler SAHTE / ENGELLENDİ sayılır.",
            value: tuning.suspiciousThreshold,
            min: 40,
            max: 90,
            color: AppTheme.suspicious,
            onChanged: (val) =>
                tuningNotifier.updateSuspiciousThreshold(val.toInt()),
          ),

          const SizedBox(height: 24),

          // 5. Save & Apply Action Button
          ElevatedButton.icon(
            onPressed: () async {
              await tuningNotifier.saveToStorage();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "✅ Kalibrasyon ayarları kaydedildi ve canlı sisteme uygulandı! (${tuning.profileKey.toUpperCase()})",
                    ),
                    backgroundColor: AppTheme.safe,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            label: const Text(
              "Kalibrasyonu Kaydet & Canlı Uygula",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(
    BuildContext context,
    String activeKey,
    RiskTuningNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3547)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ÖN AYAR PROFİLLERİ (PRESETS)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildPresetButton(
                  title: "🛡️ Dengeli",
                  keyName: 'balanced',
                  isActive: activeKey == 'balanced',
                  onTap: () => notifier.setPreset('balanced'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  title: "🔒 Katı",
                  keyName: 'strict',
                  isActive: activeKey == 'strict',
                  onTap: () => notifier.setPreset('strict'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  title: "⚡ Saha",
                  keyName: 'permissive',
                  isActive: activeKey == 'permissive',
                  onTap: () => notifier.setPreset('permissive'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  title: "🧪 Özel",
                  keyName: 'custom',
                  isActive: activeKey == 'custom',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton({
    required String title,
    required String keyName,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withAlpha(50)
              : const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppTheme.primary : const Color(0xFF2A3547),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSandboxCard(
    BuildContext context,
    RiskTuningConfig tuning,
    SandboxFlags flags,
    SandboxNotifier notifier,
    int score,
    RiskCategory category,
  ) {
    Color badgeColor;
    IconData badgeIcon;

    switch (category) {
      case RiskCategory.safe:
        badgeColor = AppTheme.safe;
        badgeIcon = Icons.check_circle_rounded;
        break;
      case RiskCategory.suspicious:
        badgeColor = AppTheme.suspicious;
        badgeIcon = Icons.warning_rounded;
        break;
      case RiskCategory.spoofed:
        badgeColor = AppTheme.spoofed;
        badgeIcon = Icons.gpp_bad_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E293B), badgeColor.withAlpha(30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.science_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "CANLI KALİBRASYON TEST ALANI",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              if (flags.isAnyActive())
                InkWell(
                  onTap: () => notifier.reset(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      "Temizle",
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Score and Verdict Display
          Row(
            children: [
              // Score Radial Box
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$score",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                      const Text(
                        "/100",
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            category.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category == RiskCategory.safe
                          ? "Check-in işlemi onaylanır (≤${tuning.safeThreshold} puan)."
                          : (category == RiskCategory.suspicious
                                ? "Check-in bekletilir (≤${tuning.suspiciousThreshold} puan)."
                                : "Check-in engellenir ve alarm logu düşer (> ${tuning.suspiciousThreshold} puan)."),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),

          const Text(
            "Anomalileri Aç / Kapa (Simülasyon):",
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),

          // Anomaly Filter Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildSandboxChip(
                "K1: OS Mock (+${tuning.k1OsMock})",
                flags.k1Active,
                notifier.toggleK1,
              ),
              _buildSandboxChip(
                "K2: Mock App (+${tuning.k2MockApp})",
                flags.k2Active,
                notifier.toggleK2,
              ),
              _buildSandboxChip(
                "K3: Geliştirici (+${tuning.k3DevMode})",
                flags.k3Active,
                notifier.toggleK3,
              ),
              _buildSandboxChip(
                "K4: Hız (+${tuning.k4Speed})",
                flags.k4Active,
                notifier.toggleK4,
              ),
              _buildSandboxChip(
                "K5: İvmeölçer (+${tuning.k5Sensor})",
                flags.k5Active,
                notifier.toggleK5,
              ),
              _buildSandboxChip(
                "K6: Root (+${tuning.k6Integrity})",
                flags.k6Active,
                notifier.toggleK6,
              ),
              _buildSandboxChip(
                "K7: VPN (+${tuning.k7Vpn})",
                flags.k7Active,
                notifier.toggleK7,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSandboxChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCoefficientSlider({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3547)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(100)),
                ),
                child: Text(
                  "+$value Puan",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF2A3547),
              thumbColor: color,
              overlayColor: color.withAlpha(50),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdCard({
    required String title,
    required String subtitle,
    required int value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3547)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: Text(
                  "≤ $value",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF2A3547),
              thumbColor: color,
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble().clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min)).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
