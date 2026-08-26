import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimulationConfig {
  final bool simulateMockLocation;
  final bool simulateDevMode;
  final bool simulateSpeedAnomaly;
  final bool simulateSensorInconsistency;
  final bool simulateRooted;
  final bool simulateEmulator;
  final bool simulateVpn;
  final bool simulateApiOffline;
  final bool simulatePlayIntegrityFail;
  final bool simulateBiometricFail;

  const SimulationConfig({
    required this.simulateMockLocation,
    required this.simulateDevMode,
    required this.simulateSpeedAnomaly,
    required this.simulateSensorInconsistency,
    required this.simulateRooted,
    required this.simulateEmulator,
    required this.simulateVpn,
    required this.simulateApiOffline,
    required this.simulatePlayIntegrityFail,
    required this.simulateBiometricFail,
  });

  factory SimulationConfig.initial() {
    return const SimulationConfig(
      simulateMockLocation: false,
      simulateDevMode: false,
      simulateSpeedAnomaly: false,
      simulateSensorInconsistency: false,
      simulateRooted: false,
      simulateEmulator: false,
      simulateVpn: false,
      simulateApiOffline: false,
      simulatePlayIntegrityFail: false,
      simulateBiometricFail: false,
    );
  }

  SimulationConfig copyWith({
    bool? simulateMockLocation,
    bool? simulateDevMode,
    bool? simulateSpeedAnomaly,
    bool? simulateSensorInconsistency,
    bool? simulateRooted,
    bool? simulateEmulator,
    bool? simulateVpn,
    bool? simulateApiOffline,
    bool? simulatePlayIntegrityFail,
    bool? simulateBiometricFail,
  }) {
    return SimulationConfig(
      simulateMockLocation: simulateMockLocation ?? this.simulateMockLocation,
      simulateDevMode: simulateDevMode ?? this.simulateDevMode,
      simulateSpeedAnomaly: simulateSpeedAnomaly ?? this.simulateSpeedAnomaly,
      simulateSensorInconsistency: simulateSensorInconsistency ?? this.simulateSensorInconsistency,
      simulateRooted: simulateRooted ?? this.simulateRooted,
      simulateEmulator: simulateEmulator ?? this.simulateEmulator,
      simulateVpn: simulateVpn ?? this.simulateVpn,
      simulateApiOffline: simulateApiOffline ?? this.simulateApiOffline,
      simulatePlayIntegrityFail: simulatePlayIntegrityFail ?? this.simulatePlayIntegrityFail,
      simulateBiometricFail: simulateBiometricFail ?? this.simulateBiometricFail,
    );
  }
}

class SimulationNotifier extends StateNotifier<SimulationConfig> {
  SimulationNotifier() : super(SimulationConfig.initial());

  void toggleMockLocation(bool val) => state = state.copyWith(simulateMockLocation: val);
  void toggleDevMode(bool val) => state = state.copyWith(simulateDevMode: val);
  void toggleSpeedAnomaly(bool val) => state = state.copyWith(simulateSpeedAnomaly: val);
  void toggleSensorInconsistency(bool val) => state = state.copyWith(simulateSensorInconsistency: val);
  void toggleRooted(bool val) => state = state.copyWith(simulateRooted: val);
  void toggleEmulator(bool val) => state = state.copyWith(simulateEmulator: val);
  void toggleVpn(bool val) => state = state.copyWith(simulateVpn: val);
  void toggleApiOffline(bool val) => state = state.copyWith(simulateApiOffline: val);
  void togglePlayIntegrityFail(bool val) => state = state.copyWith(simulatePlayIntegrityFail: val);
  void toggleBiometricFail(bool val) => state = state.copyWith(simulateBiometricFail: val);
}

final simulationProvider = StateNotifierProvider<SimulationNotifier, SimulationConfig>((ref) {
  return SimulationNotifier();
});
