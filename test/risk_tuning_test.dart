import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waypoint_app/features/location_map/domain/entities/location_data.dart';
import 'package:waypoint_app/features/location_map/presentation/providers/location_providers.dart';
import 'package:waypoint_app/features/location_map/presentation/providers/antispoofing_providers.dart';
import 'package:waypoint_app/features/settings/domain/entities/risk_tuning_config.dart';
import 'package:waypoint_app/features/settings/presentation/providers/risk_tuning_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RiskTuningConfig Entity Tests', () {
    test('Balanced preset has expected standard weights and thresholds', () {
      final config = RiskTuningConfig.balanced();
      expect(config.k1OsMock, equals(75));
      expect(config.k2MockApp, equals(50));
      expect(config.k3DevMode, equals(35));
      expect(config.k4Speed, equals(70));
      expect(config.k5Sensor, equals(40));
      expect(config.k6Integrity, equals(60));
      expect(config.k7Vpn, equals(45));
      expect(config.safeThreshold, equals(34));
      expect(config.suspiciousThreshold, equals(69));
      expect(config.profileKey, equals('balanced'));
    });

    test(
      'Strict and Permissive presets configure appropriate security levels',
      () {
        final strict = RiskTuningConfig.strict();
        expect(strict.k1OsMock, equals(85));
        expect(strict.k6Integrity, equals(90));
        expect(strict.safeThreshold, equals(25));
        expect(strict.suspiciousThreshold, equals(55));

        final permissive = RiskTuningConfig.permissive();
        expect(permissive.k1OsMock, equals(50));
        expect(permissive.safeThreshold, equals(45));
        expect(permissive.suspiciousThreshold, equals(75));
      },
    );

    test(
      'calculateTotalScore sums active flags and clamps between 0 and 100',
      () {
        final config = RiskTuningConfig.balanced();

        // No anomalies
        expect(config.calculateTotalScore(), equals(0));

        // Single K3 anomaly (+35)
        expect(config.calculateTotalScore(isK3: true), equals(35));

        // K1 (+75) + K3 (+35) = 110 -> clamped to 100
        expect(config.calculateTotalScore(isK1: true, isK3: true), equals(100));

        // K5 (+40) + K7 (+45) = 85
        expect(config.calculateTotalScore(isK5: true, isK7: true), equals(85));
      },
    );

    test('getCategory assigns correct RiskCategory based on thresholds', () {
      final config = RiskTuningConfig.balanced();

      // Score 0-34: Safe
      expect(config.getCategory(0), equals(RiskCategory.safe));
      expect(config.getCategory(34), equals(RiskCategory.safe));

      // Score 35-69: Suspicious
      expect(config.getCategory(35), equals(RiskCategory.suspicious));
      expect(config.getCategory(69), equals(RiskCategory.suspicious));

      // Score 70-100: Spoofed
      expect(config.getCategory(70), equals(RiskCategory.spoofed));
      expect(config.getCategory(100), equals(RiskCategory.spoofed));
    });

    test('Serialization toMap and fromMap preserves all fields', () {
      final original = RiskTuningConfig.strict();
      final map = original.toMap();
      final restored = RiskTuningConfig.fromMap(map);

      expect(restored.k1OsMock, equals(original.k1OsMock));
      expect(restored.k6Integrity, equals(original.k6Integrity));
      expect(restored.safeThreshold, equals(original.safeThreshold));
      expect(restored.profileKey, equals(original.profileKey));
    });
  });

  group('RiskTuningNotifier & Sandbox Providers Tests', () {
    test(
      'RiskTuningNotifier updates individual weights and sets profile to custom',
      () {
        final container = ProviderContainer();
        final notifier = container.read(riskTuningProvider.notifier);

        expect(
          container.read(riskTuningProvider).profileKey,
          equals('balanced'),
        );

        notifier.updateK1(95);
        expect(container.read(riskTuningProvider).k1OsMock, equals(95));
        expect(container.read(riskTuningProvider).profileKey, equals('custom'));

        notifier.updateSafeThreshold(20);
        expect(container.read(riskTuningProvider).safeThreshold, equals(20));

        notifier.setPreset('strict');
        expect(container.read(riskTuningProvider).profileKey, equals('strict'));
        expect(container.read(riskTuningProvider).k1OsMock, equals(85));

        notifier.resetToDefaults();
        expect(
          container.read(riskTuningProvider).profileKey,
          equals('balanced'),
        );
        expect(container.read(riskTuningProvider).k1OsMock, equals(75));

        container.dispose();
      },
    );

    test(
      'SandboxScoreProvider updates live score as sandbox flags are toggled',
      () {
        final container = ProviderContainer();
        final sandboxNotifier = container.read(sandboxFlagsProvider.notifier);

        expect(container.read(sandboxScoreProvider), equals(0));

        // Toggle K1 (75 pts)
        sandboxNotifier.toggleK1();
        expect(container.read(sandboxScoreProvider), equals(75));

        // Toggle K5 (40 pts) -> 75 + 40 = 115 -> clamped to 100
        sandboxNotifier.toggleK5();
        expect(container.read(sandboxScoreProvider), equals(100));

        // Reset
        sandboxNotifier.reset();
        expect(container.read(sandboxScoreProvider), equals(0));

        container.dispose();
      },
    );

    test(
      'AntispoofingNotifier dynamically responds to custom risk tuning weights',
      () async {
        final locationController = StreamController<LocationData>();

        final container = ProviderContainer(
          overrides: [
            locationStreamProvider.overrideWith(
              (ref) => locationController.stream,
            ),
          ],
        );

        // Keep antispoofing provider active
        container.listen(antispoofingProvider, (prev, next) {});

        // 1. Emit an OS-mocked location
        final location = LocationData(
          latitude: 41.0082,
          longitude: 28.9784,
          speed: 0.0,
          accuracy: 3.0,
          bearing: 0.0,
          timestamp: DateTime.now(),
          isMocked: true, // K1 active
        );

        locationController.add(location);
        await Future.delayed(const Duration(milliseconds: 15));

        // With default balanced preset, K1 = 75
        var riskState = container.read(antispoofingProvider);
        expect(riskState.riskScore, equals(75));
        expect(riskState.riskCategory, equals(RiskCategory.spoofed));

        // 2. Dynamically change K1 weight to 30 (which brings score down to safe threshold ≤ 34)
        container.read(riskTuningProvider.notifier).updateK1(30);
        await Future.delayed(const Duration(milliseconds: 15));

        riskState = container.read(antispoofingProvider);
        expect(riskState.riskScore, equals(30));
        expect(riskState.riskCategory, equals(RiskCategory.safe));

        // 3. Switch preset to Strict (K1 = 85)
        container.read(riskTuningProvider.notifier).setPreset('strict');
        await Future.delayed(const Duration(milliseconds: 15));

        riskState = container.read(antispoofingProvider);
        expect(riskState.riskScore, equals(85));
        expect(riskState.riskCategory, equals(RiskCategory.spoofed));

        await locationController.close();
        container.dispose();
      },
    );
  });
}
