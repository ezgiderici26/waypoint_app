import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/location_map/presentation/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive local database
  await Hive.initFlutter();
  await Hive.openBox('check_in_box');

  runApp(
    const ProviderScope(
      child: WaypointApp(),
    ),
  );
}

class WaypointApp extends StatelessWidget {
  const WaypointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waypoint Safe Check-in',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
    );
  }
}
