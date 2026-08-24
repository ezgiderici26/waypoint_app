import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import '../providers/location_providers.dart';
import '../../domain/entities/location_data.dart';
import '../../../../core/providers/simulation_provider.dart';

class RiskState {
  final LocationData? currentLocation;
  final LocationData? previousLocation;
  final double computedSpeedKmh;
  
  // Antispoofing Check Flags
  final bool isOsMocked;          // K1
  final bool isDevModeActive;      // K3
  final bool isSpeedImpossible;    // K4
  final bool isSensorInconsistent; // K5
  
  final int riskScore;             // 0-100 normalized score

  const RiskState({
    this.currentLocation,
    this.previousLocation,
    required this.computedSpeedKmh,
    required this.isOsMocked,
    required this.isDevModeActive,
    required this.isSpeedImpossible,
    required this.isSensorInconsistent,
    required this.riskScore,
  });

  factory RiskState.initial() {
    return const RiskState(
      computedSpeedKmh: 0,
      isOsMocked: false,
      isDevModeActive: false,
      isSpeedImpossible: false,
      isSensorInconsistent: false,
      riskScore: 0,
    );
  }

  RiskState copyWith({
    LocationData? currentLocation,
    LocationData? previousLocation,
    double? computedSpeedKmh,
    bool? isOsMocked,
    bool? isDevModeActive,
    bool? isSpeedImpossible,
    bool? isSensorInconsistent,
    int? riskScore,
  }) {
    return RiskState(
      currentLocation: currentLocation ?? this.currentLocation,
      previousLocation: previousLocation ?? this.previousLocation,
      computedSpeedKmh: computedSpeedKmh ?? this.computedSpeedKmh,
      isOsMocked: isOsMocked ?? this.isOsMocked,
      isDevModeActive: isDevModeActive ?? this.isDevModeActive,
      isSpeedImpossible: isSpeedImpossible ?? this.isSpeedImpossible,
      isSensorInconsistent: isSensorInconsistent ?? this.isSensorInconsistent,
      riskScore: riskScore ?? this.riskScore,
    );
  }
}

class AntispoofingNotifier extends StateNotifier<RiskState> {
  final Ref _ref;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  
  // Sliding window to calculate device movement magnitude (K5)
  final List<double> _accelMagnitudes = [];
  static const int _maxWindowSize = 10;
  
  bool _devModeActive = false;

  AntispoofingNotifier(this._ref) : super(RiskState.initial()) {
    _initSensors();
    _checkDevMode();

    // Listen to locationStreamProvider to update risk calculations in real time
    _ref.listen<AsyncValue<LocationData>>(locationStreamProvider, (previous, next) {
      next.whenData((LocationData newLocation) {
        _evaluateLocation(newLocation);
      });
    });

    // Re-evaluate when simulation configuration changes
    _ref.listen<SimulationConfig>(simulationProvider, (_, __) {
      if (state.currentLocation != null) {
        _evaluateLocation(state.currentLocation!);
      }
    });
  }

  void _initSensors() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    
    _accelerometerSub = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _accelMagnitudes.add(magnitude);
      if (_accelMagnitudes.length > _maxWindowSize) {
        _accelMagnitudes.removeAt(0);
      }
    });
  }

  Future<void> _checkDevMode() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      _devModeActive = await FlutterJailbreakDetection.developerMode;
    } catch (_) {
      _devModeActive = false;
    }
  }

  void _evaluateLocation(LocationData newLocation) {
    final prevLocation = state.currentLocation;
    bool speedImpossible = false;
    bool sensorInconsistent = false;
    double computedSpeedKmh = 0.0;

    // Load simulation configs
    final sim = _ref.read(simulationProvider);

    if (prevLocation != null) {
      final repository = _ref.read(locationRepositoryProvider);
      final double distanceMeters = repository.calculateDistance(
        prevLocation.latitude,
        prevLocation.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      final double timeSeconds = newLocation.timestamp
          .difference(prevLocation.timestamp)
          .inMilliseconds / 1000.0;

      if (timeSeconds > 0.5) {
        final double speedMps = distanceMeters / timeSeconds;
        computedSpeedKmh = speedMps * 3.6;

        // K4: Speed Anomaly (> 150 km/h)
        if (computedSpeedKmh > 150.0 || sim.simulateSpeedAnomaly) {
          speedImpossible = true;
        }

        // K5: Sensor Cross-Validation
        final double prevSpeedMps = prevLocation.speed;
        final double currentSpeedMps = newLocation.speed;
        final double gpsAcceleration = (currentSpeedMps - prevSpeedMps).abs() / timeSeconds;

        if (gpsAcceleration > 0.5 && _accelMagnitudes.isNotEmpty) {
          final double avgAccel = _accelMagnitudes.reduce((a, b) => a + b) / _accelMagnitudes.length;
          if (avgAccel < 0.1) {
            sensorInconsistent = true;
          }
        }
      }
    }

    if (sim.simulateSpeedAnomaly) {
      speedImpossible = true;
      if (computedSpeedKmh == 0.0) {
        computedSpeedKmh = 185.0; // Mock high speed
      }
    }
    if (sim.simulateSensorInconsistency) {
      sensorInconsistent = true;
    }

    // Check OS Mock Flag (K1)
    final bool osMocked = sim.simulateMockLocation ? true : newLocation.isMocked;
    final bool devModeActive = sim.simulateDevMode ? true : _devModeActive;

    // Calculate Normalized Weighted Risk Score (0-100)
    int score = 0;
    
    if (osMocked) {
      score += 75;
    }
    if (speedImpossible) {
      score += 70;
    }
    if (devModeActive) {
      score += 35;
    }
    if (sensorInconsistent) {
      score += 40;
    }

    if (score > 100) score = 100;

    state = RiskState(
      currentLocation: newLocation,
      previousLocation: prevLocation,
      computedSpeedKmh: computedSpeedKmh,
      isOsMocked: osMocked,
      isDevModeActive: devModeActive,
      isSpeedImpossible: speedImpossible,
      isSensorInconsistent: sensorInconsistent,
      riskScore: score,
    );
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }
}

final antispoofingProvider = StateNotifierProvider<AntispoofingNotifier, RiskState>((ref) {
  return AntispoofingNotifier(ref);
});
