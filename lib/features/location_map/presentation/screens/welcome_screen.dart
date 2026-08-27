import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/home_shell.dart';
import '../providers/location_providers.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionProvider);
    final permissionNotifier = ref.read(permissionProvider.notifier);

    // If permission is already granted (either while-in-use or always), we can automatically redirect or let them proceed.
    // However, to show the UX difference clearly, we will provide custom flows on this screen.

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Central Branding
              Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(51),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      size: 50,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "WAYPOINT",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Güvenli Konum & Antispoofing Doğrulama",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Interactive permission UI box
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildPermissionStatusBox(
                    context,
                    permissionState,
                    permissionNotifier,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Feature Highlights & Call-to-action
              Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.security_rounded,
                    title: "Gelişmiş Antispoofing",
                    subtitle:
                        "OS Mock sağlayıcıları, teleportasyon ve sensör tutarsızlık tespiti.",
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    icon: Icons.my_location_rounded,
                    title: "Geofence Check-in",
                    subtitle:
                        "Belirlenen hedef noktalarında güvenli ve doğrulanmış check-in.",
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStatusBox(
    BuildContext context,
    PermissionState state,
    PermissionNotifier notifier,
  ) {
    switch (state) {
      case PermissionState.checking:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                "Konum İzin Durumu Kontrol Ediliyor...",
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        );

      case PermissionState.denied:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_off_rounded,
                  color: AppTheme.suspicious,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Konum İzni Gerekli",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Uygulamanın çalışması için konum izni gereklidir. İlk adımda 'Uygulamayı Kullanırken' iznini etkinleştirin.",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => notifier.requestWhileInUsePermission(),
                child: const Text("Konum İznini Başlat"),
              ),
            ),
          ],
        );

      case PermissionState.deniedForever:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gpp_bad_rounded, color: AppTheme.spoofed, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "İzinler Kalıcı Olarak Devre Dışı",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.spoofed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Konum izinleri kalıcı olarak reddedildi. Uygulamayı kullanabilmek için ayarlardan izin vermeniz gerekir.",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.spoofed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => notifier.openSettings(),
                child: const Text("Sistem Ayarlarını Aç"),
              ),
            ),
          ],
        );

      case PermissionState.whileInUse:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.safe,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kullanım İzni Aktif",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.safe,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Kullanım izni sağlandı. Arka planda koruma ve sapma tespiti için konum iznini 'Her Zaman' (Always) yapmanız tavsiye edilir.",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2A3547)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeShell()),
                      );
                    },
                    child: const Text("Geç ve Devam Et"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => notifier.requestAlwaysPermission(),
                    child: const Text("Her Zaman İzin Ver"),
                  ),
                ),
              ],
            ),
          ],
        );

      case PermissionState.always:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.safe,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tam Yetki Etkinleştirildi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Her Zaman (Always) izni sağlandı! Maksimum güvenlik ve arka plan antispoofing aktif edildi.",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeShell()),
                  );
                },
                child: const Text("Uygulamaya Git"),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A3547)),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
