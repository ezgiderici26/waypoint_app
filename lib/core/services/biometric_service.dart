import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final Ref _ref;

  BiometricService(this._ref);

  Future<bool> isBiometricsAvailable() async {
    final sim = _ref.read(simulationProvider);
    if (sim.simulateEmulator) {
      return true; // Simulate available on emulator for test
    }
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    final sim = _ref.read(simulationProvider);
    if (sim.simulateBiometricFail) {
      return false;
    }
    if (sim.simulateEmulator) {
      // Simulate biometric verification delay on emulators for testing UI
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    }

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
            'Check-in işlemini tamamlamak için biyometrik kimliğinizi doğrulayın.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(ref);
});
