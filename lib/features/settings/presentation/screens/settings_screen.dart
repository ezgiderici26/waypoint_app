import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../location_map/presentation/providers/location_providers.dart';
import '../../../location_map/presentation/providers/geofence_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/providers/simulation_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _mockPreventionEnabled = true;

  void _showGeofenceLogsDialog(
    BuildContext context,
    GeofenceState geofenceState,
    GeofenceNotifier geofenceNotifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A3547), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "GEOFENCE OLAY GÜNLÜĞÜ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (geofenceState.eventsHistory.isNotEmpty)
                  TextButton(
                    onPressed: () => geofenceNotifier.clearEvents(),
                    child: const Text(
                      "Temizle",
                      style: TextStyle(color: AppTheme.spoofed, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (geofenceState.eventsHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    "Henüz geofence giriş/çıkış olayı kaydedilmedi.\nSimülasyon butonlarını deneyebilirsiniz.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: geofenceState.eventsHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = geofenceState.eventsHistory[index];
                    final isEnter = event.type == 'ENTER';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isEnter
                              ? AppTheme.safe.withAlpha(80)
                              : AppTheme.suspicious.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEnter
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            color: isEnter
                                ? AppTheme.safe
                                : AppTheme.suspicious,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEnter
                                      ? "HEDEFE GİRİLDİ (Check-in Aktif)"
                                      : "HEDEFTEN ÇIKILDI",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isEnter
                                        ? AppTheme.safe
                                        : AppTheme.suspicious,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${event.targetName} • Mesafe: ${event.distanceMeters.toInt()}m",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
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

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(targetLocationProvider);
    final targetNotifier = ref.read(targetLocationProvider.notifier);

    // Watch Geofence Provider
    final geofenceState = ref.watch(geofenceProvider);
    final geofenceNotifier = ref.read(geofenceProvider.notifier);

    // Watch and read Simulation Provider
    final simConfig = ref.watch(simulationProvider);
    final simNotifier = ref.read(simulationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("AYARLAR VE HEDEFLER")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Target Preset
          const Text(
            "HEDEF KONTROL NOKTASI",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hedef Bölge Preset Seçimi",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: target.name,
                    dropdownColor: AppTheme.surface,
                    decoration: const InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2A3547)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Kadıköy Meydan",
                        child: Text("Kadıköy Meydan (40.9905, 29.0255)"),
                      ),
                      DropdownMenuItem(
                        value: "Beşiktaş Sahil",
                        child: Text("Beşiktaş Sahil (41.0428, 29.0075)"),
                      ),
                      DropdownMenuItem(
                        value: "Taksim Metro",
                        child: Text("Taksim Metro (41.0370, 28.9850)"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        double lat = 40.9905;
                        double lng = 29.0255;
                        if (val == "Beşiktaş Sahil") {
                          lat = 41.0428;
                          lng = 29.0075;
                        } else if (val == "Taksim Metro") {
                          lat = 41.0370;
                          lng = 28.9850;
                        }

                        targetNotifier.state = TargetLocation(
                          name: val,
                          latitude: lat,
                          longitude: lng,
                          radius: target.radius,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Geofence Yarıçapı: ${target.radius.toStringAsFixed(0)} m",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: target.radius,
                          min: 50.0,
                          max: 1000.0,
                          divisions: 19,
                          activeColor: AppTheme.primary,
                          inactiveColor: AppTheme.textSecondary.withAlpha(51),
                          onChanged: (val) {
                            targetNotifier.state = TargetLocation(
                              name: target.name,
                              latitude: target.latitude,
                              longitude: target.longitude,
                              radius: val,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Geofence & Notifications Settings
          const Text(
            "GEOFENCE VE ARKA PLAN BİLDİRİMLERİ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: geofenceState.notificationsEnabled,
                  activeThumbColor: AppTheme.primary,
                  title: const Text(
                    "Geofence Giriş/Çıkış Bildirimleri",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    "Hedef alana girildiğinde ve çıkıldığında anlık push bildirimi gönderir.",
                    style: TextStyle(fontSize: 12),
                  ),
                  onChanged: (val) => geofenceNotifier.toggleNotifications(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    "Test Bildirimi Gönder",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    "Cihazda push bildirim izinlerini ve servisini test eder.",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () async {
                    await NotificationService().showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Test bildirimi cihaza gönderildi!"),
                          backgroundColor: AppTheme.safe,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                ListTile(
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AppTheme.secondary,
                  ),
                  title: const Text(
                    "Geofence Olay Geçmişi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    "${geofenceState.eventsHistory.length} giriş/çıkış olayı kaydedildi",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () => _showGeofenceLogsDialog(
                    context,
                    geofenceState,
                    geofenceNotifier,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Antispoofing Settings
          const Text(
            "ANTISPOOFING PARAMETRELERİ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _mockPreventionEnabled,
                  activeThumbColor: AppTheme.primary,
                  title: const Text(
                    "Katı Sahte Konum Koruması",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    "Herhangi bir mock bayrağı yakalandığında check-in işlemini tamamen bloke eder.",
                    style: TextStyle(fontSize: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _mockPreventionEnabled = val;
                    });
                  },
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                ListTile(
                  title: const Text(
                    "İmkânsız Hız Toleransı",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text("Maksimum hız limiti: 150 km/s"),
                  trailing: const Icon(
                    Icons.speed_rounded,
                    color: AppTheme.primary,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Simulation & Manual Testing Mode
          const Text(
            "SİMÜLASYON / TEST SEÇENEKLERİ (DEMO)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.suspicious,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                // Geofence Instant Entry / Exit Simulation Actions
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text(
                            "Alana Giriş Simüle Et",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.safe,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () async {
                            await geofenceNotifier.simulateGeofenceEnter();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "📍 Hedef alana giriş simüle edildi & bildirim gönderildi!",
                                  ),
                                  backgroundColor: AppTheme.safe,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text(
                            "Alandan Çıkış Simüle Et",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.suspicious,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () async {
                            await geofenceNotifier.simulateGeofenceExit();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "🚪 Hedef alandan çıkış simüle edildi & bildirim gönderildi!",
                                  ),
                                  backgroundColor: AppTheme.suspicious,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateMockLocation,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("Sahte Konum Tetikle (K1)"),
                  onChanged: (val) => simNotifier.toggleMockLocation(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateSpeedAnomaly,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("İmkânsız Hız/Işınlanma Tetikle (K4)"),
                  onChanged: (val) => simNotifier.toggleSpeedAnomaly(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateDevMode,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("Geliştirici Modunu Tetikle (K3)"),
                  onChanged: (val) => simNotifier.toggleDevMode(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateSensorInconsistency,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("Sensör Tutarsızlığı Tetikle (K5)"),
                  onChanged: (val) =>
                      simNotifier.toggleSensorInconsistency(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateRooted,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("Rooted/Jailbreak Tetikle"),
                  onChanged: (val) => simNotifier.toggleRooted(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateEmulator,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("Emülatör Ortamı Tetikle"),
                  onChanged: (val) => simNotifier.toggleEmulator(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateVpn,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("VPN / Proxy Bağlantısı Tetikle"),
                  onChanged: (val) => simNotifier.toggleVpn(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateApiOffline,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("API Sunucusunu Çevrimdışı Simüle Et"),
                  onChanged: (val) => simNotifier.toggleApiOffline(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulatePlayIntegrityFail,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text(
                    "Play Integrity / App Attest İhlali Tetikle",
                  ),
                  onChanged: (val) => simNotifier.togglePlayIntegrityFail(val),
                ),
                const Divider(height: 1, color: Color(0xFF2A3547)),
                SwitchListTile(
                  value: simConfig.simulateBiometricFail,
                  activeThumbColor: AppTheme.suspicious,
                  title: const Text("Biyometrik Hata Simüle Et"),
                  onChanged: (val) => simNotifier.toggleBiometricFail(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
