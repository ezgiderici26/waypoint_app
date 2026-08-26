import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waypoint_app/core/utils/encryption_helper.dart';
import 'package:waypoint_app/core/services/biometric_service.dart';
import 'package:waypoint_app/core/providers/simulation_provider.dart';
import 'package:waypoint_app/features/check_in/domain/entities/check_in_record.dart';

void main() {
  group('EncryptionHelper Unit Tests', () {
    test('AES-256 Encrypt and Decrypt integrity test', () {
      const originalPayload =
          '{"id":"test-123","riskScore":25,"targetName":"Test HQ"}';

      final encrypted = EncryptionHelper.encrypt(originalPayload);
      expect(encrypted, isNot(equals(originalPayload)));
      expect(encrypted.isNotEmpty, isTrue);

      final decrypted = EncryptionHelper.decrypt(encrypted);
      expect(decrypted, equals(originalPayload));
    });

    test('CheckInRecord serialization with Encryption round-trip', () {
      final record = CheckInRecord(
        id: 'rec-001',
        timestamp: DateTime.now().toIso8601String(),
        latitude: 41.0082,
        longitude: 28.9784,
        accuracy: 4.5,
        riskScore: 15,
        deviceStatus: 'Rooted: false, Emulator: false, VPN: false',
        targetName: 'Ana Merkez Noktası',
        isSynced: false,
        isBlocked: false,
      );

      final jsonString = jsonEncode(record.toJson());
      final encrypted = EncryptionHelper.encrypt(jsonString);
      final decrypted = EncryptionHelper.decrypt(encrypted);
      final restored = CheckInRecord.fromJson(jsonDecode(decrypted));

      expect(restored.id, equals(record.id));
      expect(restored.latitude, equals(record.latitude));
      expect(restored.riskScore, equals(record.riskScore));
      expect(restored.targetName, equals(record.targetName));
    });
  });

  group('BiometricService Simulation Tests', () {
    test(
      'BiometricService simulates failure when simulation flag is active',
      () async {
        final container = ProviderContainer();
        final simNotifier = container.read(simulationProvider.notifier);
        final biometricService = container.read(biometricServiceProvider);

        // Trigger biometric fail simulation
        simNotifier.toggleBiometricFail(true);
        final result = await biometricService.authenticate();
        expect(result, isFalse);

        container.dispose();
      },
    );

    test(
      'BiometricService simulates success when emulator simulation is active',
      () async {
        final container = ProviderContainer();
        final simNotifier = container.read(simulationProvider.notifier);
        final biometricService = container.read(biometricServiceProvider);

        // Disable biometric fail, enable emulator simulation
        simNotifier.toggleBiometricFail(false);
        simNotifier.toggleEmulator(true);

        final isAvailable = await biometricService.isBiometricsAvailable();
        expect(isAvailable, isTrue);

        final result = await biometricService.authenticate();
        expect(result, isTrue);

        container.dispose();
      },
    );
  });
}
