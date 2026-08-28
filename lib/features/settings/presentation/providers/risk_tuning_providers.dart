import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/risk_tuning_config.dart';

const String _kSettingsBoxName = 'settings_box';
const String _kRiskTuningKey = 'risk_tuning_config';

class RiskTuningNotifier extends StateNotifier<RiskTuningConfig> {
  RiskTuningNotifier() : super(RiskTuningConfig.balanced()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      if (!Hive.isBoxOpen(_kSettingsBoxName)) {
        await Hive.openBox(_kSettingsBoxName);
      }
      final box = Hive.box(_kSettingsBoxName);
      final storedData = box.get(_kRiskTuningKey);
      if (storedData != null && storedData is Map) {
        state = RiskTuningConfig.fromMap(storedData);
      }
    } catch (e) {
      debugPrint("RiskTuningConfig yüklenirken hata: $e");
    }
  }

  Future<void> saveToStorage() async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      if (!Hive.isBoxOpen(_kSettingsBoxName)) {
        await Hive.openBox(_kSettingsBoxName);
      }
      final box = Hive.box(_kSettingsBoxName);
      await box.put(_kRiskTuningKey, state.toMap());
    } catch (e) {
      debugPrint("RiskTuningConfig kaydedilirken hata: $e");
    }
  }

  void setPreset(String presetKey) {
    switch (presetKey) {
      case 'strict':
        state = RiskTuningConfig.strict();
        break;
      case 'permissive':
        state = RiskTuningConfig.permissive();
        break;
      case 'balanced':
      default:
        state = RiskTuningConfig.balanced();
        break;
    }
    saveToStorage();
  }

  void updateK1(int value) {
    state = state.copyWith(k1OsMock: value, profileKey: 'custom');
  }

  void updateK2(int value) {
    state = state.copyWith(k2MockApp: value, profileKey: 'custom');
  }

  void updateK3(int value) {
    state = state.copyWith(k3DevMode: value, profileKey: 'custom');
  }

  void updateK4(int value) {
    state = state.copyWith(k4Speed: value, profileKey: 'custom');
  }

  void updateK5(int value) {
    state = state.copyWith(k5Sensor: value, profileKey: 'custom');
  }

  void updateK6(int value) {
    state = state.copyWith(k6Integrity: value, profileKey: 'custom');
  }

  void updateK7(int value) {
    state = state.copyWith(k7Vpn: value, profileKey: 'custom');
  }

  void updateSafeThreshold(int value) {
    state = state.copyWith(safeThreshold: value, profileKey: 'custom');
  }

  void updateSuspiciousThreshold(int value) {
    state = state.copyWith(suspiciousThreshold: value, profileKey: 'custom');
  }

  void resetToDefaults() {
    state = RiskTuningConfig.balanced();
    saveToStorage();
  }
}

final riskTuningProvider =
    StateNotifierProvider<RiskTuningNotifier, RiskTuningConfig>((ref) {
      return RiskTuningNotifier();
    });

class LiveRiskTuningNotifier extends StateNotifier<RiskTuningConfig> {
  final Ref _ref;
  Timer? _debounceTimer;

  LiveRiskTuningNotifier(this._ref) : super(RiskTuningConfig.balanced()) {
    // Keep live config synchronized with the main tuning provider
    _ref.listen<RiskTuningConfig>(riskTuningProvider, (previous, next) {
      _onTuningChanged(next);
    }, fireImmediately: true);
  }

  void _onTuningChanged(RiskTuningConfig config) {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      state = config;
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = config;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final liveRiskTuningProvider =
    StateNotifierProvider<LiveRiskTuningNotifier, RiskTuningConfig>((ref) {
      return LiveRiskTuningNotifier(ref);
    });

// Live Sandbox Simulation Flags for the Tuning Screen Interactive Sandbox
class SandboxFlags {
  final bool k1Active;
  final bool k2Active;
  final bool k3Active;
  final bool k4Active;
  final bool k5Active;
  final bool k6Active;
  final bool k7Active;

  const SandboxFlags({
    this.k1Active = false,
    this.k2Active = false,
    this.k3Active = false,
    this.k4Active = false,
    this.k5Active = false,
    this.k6Active = false,
    this.k7Active = false,
  });

  SandboxFlags copyWith({
    bool? k1Active,
    bool? k2Active,
    bool? k3Active,
    bool? k4Active,
    bool? k5Active,
    bool? k6Active,
    bool? k7Active,
  }) {
    return SandboxFlags(
      k1Active: k1Active ?? this.k1Active,
      k2Active: k2Active ?? this.k2Active,
      k3Active: k3Active ?? this.k3Active,
      k4Active: k4Active ?? this.k4Active,
      k5Active: k5Active ?? this.k5Active,
      k6Active: k6Active ?? this.k6Active,
      k7Active: k7Active ?? this.k7Active,
    );
  }

  bool isAnyActive() =>
      k1Active ||
      k2Active ||
      k3Active ||
      k4Active ||
      k5Active ||
      k6Active ||
      k7Active;
}

class SandboxNotifier extends StateNotifier<SandboxFlags> {
  SandboxNotifier() : super(const SandboxFlags());

  void toggleK1() => state = state.copyWith(k1Active: !state.k1Active);
  void toggleK2() => state = state.copyWith(k2Active: !state.k2Active);
  void toggleK3() => state = state.copyWith(k3Active: !state.k3Active);
  void toggleK4() => state = state.copyWith(k4Active: !state.k4Active);
  void toggleK5() => state = state.copyWith(k5Active: !state.k5Active);
  void toggleK6() => state = state.copyWith(k6Active: !state.k6Active);
  void toggleK7() => state = state.copyWith(k7Active: !state.k7Active);

  void reset() => state = const SandboxFlags();
}

final sandboxFlagsProvider =
    StateNotifierProvider<SandboxNotifier, SandboxFlags>((ref) {
      return SandboxNotifier();
    });

final sandboxScoreProvider = Provider<int>((ref) {
  final tuning = ref.watch(riskTuningProvider);
  final flags = ref.watch(sandboxFlagsProvider);

  return tuning.calculateTotalScore(
    isK1: flags.k1Active,
    isK2: flags.k2Active,
    isK3: flags.k3Active,
    isK4: flags.k4Active,
    isK5: flags.k5Active,
    isK6: flags.k6Active,
    isK7: flags.k7Active,
  );
});
