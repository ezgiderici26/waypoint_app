import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../location_map/presentation/providers/location_providers.dart';
import '../../../../core/providers/simulation_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _mockPreventionEnabled = true;

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(targetLocationProvider);
    final targetNotifier = ref.read(targetLocationProvider.notifier);
    
    // Watch and read Simulation Provider
    final simConfig = ref.watch(simulationProvider);
    final simNotifier = ref.read(simulationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AYARLAR VE HEDEFLER"),
      ),
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
                  trailing: const Icon(Icons.speed_rounded, color: AppTheme.primary),
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
                  onChanged: (val) => simNotifier.toggleSensorInconsistency(val),
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
                  title: const Text("Play Integrity / App Attest İhlali Tetikle"),
                  onChanged: (val) => simNotifier.togglePlayIntegrityFail(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
