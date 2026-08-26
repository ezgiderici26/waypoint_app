import 'package:flutter/material.dart';
import '../../../location_map/presentation/screens/main_map_screen.dart';
import '../../../check_in/presentation/screens/history_screen.dart';
import '../../../heatmap/presentation/screens/admin_heatmap_screen.dart';
import '../../../security/presentation/screens/security_dashboard_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MainMapScreen(),
    HistoryScreen(),
    AdminHeatmapScreen(),
    SecurityDashboardScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF2A3547), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Harita',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Geçmiş',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot_outlined),
              activeIcon: Icon(Icons.whatshot_rounded),
              label: 'Isı Haritası',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield_rounded),
              label: 'Güvenlik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
