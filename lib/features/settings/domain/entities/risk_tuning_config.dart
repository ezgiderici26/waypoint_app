enum RiskCategory {
  safe,
  suspicious,
  spoofed;

  String get displayName {
    switch (this) {
      case RiskCategory.safe:
        return "GÜVENLİ";
      case RiskCategory.suspicious:
        return "ŞÜPHELİ";
      case RiskCategory.spoofed:
        return "SAHTE / ENGELLENDİ";
    }
  }
}

class RiskTuningConfig {
  final int k1OsMock; // K1: OS Mock Provider Flag (0-100)
  final int k2MockApp; // K2: Sahte GPS / Mock App Tespiti (0-100)
  final int k3DevMode; // K3: Geliştirici Modu / USB Hata Ayıklama (0-100)
  final int k4Speed; // K4: İmkânsız Hız / Işınlanma > 150 km/h (0-100)
  final int k5Sensor; // K5: İvmeölçer Sensör Tutarsızlığı (0-100)
  final int
  k6Integrity; // K6: Cihaz Bütünlüğü (Root / Jailbreak / Emülatör) (0-100)
  final int k7Vpn; // K7: Ağ Güvenliği (VPN / Proxy Tüneli) (0-100)

  final int safeThreshold; // Maksimum Güvenli Puanı (Örn: 34)
  final int suspiciousThreshold; // Maksimum Şüpheli Puanı (Örn: 69)
  final String profileKey; // 'balanced', 'strict', 'permissive', 'custom'

  const RiskTuningConfig({
    required this.k1OsMock,
    required this.k2MockApp,
    required this.k3DevMode,
    required this.k4Speed,
    required this.k5Sensor,
    required this.k6Integrity,
    required this.k7Vpn,
    required this.safeThreshold,
    required this.suspiciousThreshold,
    required this.profileKey,
  });

  // Varsayılan Dengeli Profil (Standart)
  factory RiskTuningConfig.balanced() {
    return const RiskTuningConfig(
      k1OsMock: 75,
      k2MockApp: 50,
      k3DevMode: 35,
      k4Speed: 70,
      k5Sensor: 40,
      k6Integrity: 60,
      k7Vpn: 45,
      safeThreshold: 34,
      suspiciousThreshold: 69,
      profileKey: 'balanced',
    );
  }

  // Katı Kurumsal Profil (Yüksek Toleranssız Güvenlik)
  factory RiskTuningConfig.strict() {
    return const RiskTuningConfig(
      k1OsMock: 85,
      k2MockApp: 70,
      k3DevMode: 50,
      k4Speed: 80,
      k5Sensor: 60,
      k6Integrity: 90,
      k7Vpn: 70,
      safeThreshold: 25,
      suspiciousThreshold: 55,
      profileKey: 'strict',
    );
  }

  // Esnek / Saha Testi Profili (Düşük Yanlış Pozitif Toleransı)
  factory RiskTuningConfig.permissive() {
    return const RiskTuningConfig(
      k1OsMock: 50,
      k2MockApp: 30,
      k3DevMode: 20,
      k4Speed: 45,
      k5Sensor: 25,
      k6Integrity: 40,
      k7Vpn: 30,
      safeThreshold: 45,
      suspiciousThreshold: 75,
      profileKey: 'permissive',
    );
  }

  RiskTuningConfig copyWith({
    int? k1OsMock,
    int? k2MockApp,
    int? k3DevMode,
    int? k4Speed,
    int? k5Sensor,
    int? k6Integrity,
    int? k7Vpn,
    int? safeThreshold,
    int? suspiciousThreshold,
    String? profileKey,
  }) {
    return RiskTuningConfig(
      k1OsMock: k1OsMock ?? this.k1OsMock,
      k2MockApp: k2MockApp ?? this.k2MockApp,
      k3DevMode: k3DevMode ?? this.k3DevMode,
      k4Speed: k4Speed ?? this.k4Speed,
      k5Sensor: k5Sensor ?? this.k5Sensor,
      k6Integrity: k6Integrity ?? this.k6Integrity,
      k7Vpn: k7Vpn ?? this.k7Vpn,
      safeThreshold: safeThreshold ?? this.safeThreshold,
      suspiciousThreshold: suspiciousThreshold ?? this.suspiciousThreshold,
      profileKey: profileKey ?? this.profileKey,
    );
  }

  int calculateTotalScore({
    bool isK1 = false,
    bool isK2 = false,
    bool isK3 = false,
    bool isK4 = false,
    bool isK5 = false,
    bool isK6 = false,
    bool isK7 = false,
  }) {
    int total = 0;
    if (isK1) total += k1OsMock;
    if (isK2) total += k2MockApp;
    if (isK3) total += k3DevMode;
    if (isK4) total += k4Speed;
    if (isK5) total += k5Sensor;
    if (isK6) total += k6Integrity;
    if (isK7) total += k7Vpn;

    if (total > 100) total = 100;
    if (total < 0) total = 0;
    return total;
  }

  RiskCategory getCategory(int score) {
    if (score <= safeThreshold) {
      return RiskCategory.safe;
    } else if (score <= suspiciousThreshold) {
      return RiskCategory.suspicious;
    } else {
      return RiskCategory.spoofed;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'k1OsMock': k1OsMock,
      'k2MockApp': k2MockApp,
      'k3DevMode': k3DevMode,
      'k4Speed': k4Speed,
      'k5Sensor': k5Sensor,
      'k6Integrity': k6Integrity,
      'k7Vpn': k7Vpn,
      'safeThreshold': safeThreshold,
      'suspiciousThreshold': suspiciousThreshold,
      'profileKey': profileKey,
    };
  }

  factory RiskTuningConfig.fromMap(Map<dynamic, dynamic> map) {
    return RiskTuningConfig(
      k1OsMock: map['k1OsMock'] as int? ?? 75,
      k2MockApp: map['k2MockApp'] as int? ?? 50,
      k3DevMode: map['k3DevMode'] as int? ?? 35,
      k4Speed: map['k4Speed'] as int? ?? 70,
      k5Sensor: map['k5Sensor'] as int? ?? 40,
      k6Integrity: map['k6Integrity'] as int? ?? 60,
      k7Vpn: map['k7Vpn'] as int? ?? 45,
      safeThreshold: map['safeThreshold'] as int? ?? 34,
      suspiciousThreshold: map['suspiciousThreshold'] as int? ?? 69,
      profileKey: map['profileKey'] as String? ?? 'custom',
    );
  }
}
