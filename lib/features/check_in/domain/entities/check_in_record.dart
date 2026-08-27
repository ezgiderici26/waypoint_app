class CheckInRecord {
  final String id;
  final String timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final int riskScore;
  final String deviceStatus;
  final String targetName;
  final bool isSynced;
  final bool isBlocked;

  /// Türkiye plaka kodu (1-81). Seçilen ilin plakasına karşılık gelir.
  /// Eski kayıtlarla geriye dönük uyumluluk için nullable tutulmuştur.
  final int? plateCode;

  const CheckInRecord({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.riskScore,
    required this.deviceStatus,
    required this.targetName,
    required this.isSynced,
    required this.isBlocked,
    this.plateCode, // nullable - eski kayıtlar null döndürür
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'riskScore': riskScore,
      'deviceStatus': deviceStatus,
      'targetName': targetName,
      'isSynced': isSynced,
      'isBlocked': isBlocked,
      if (plateCode != null) 'plateCode': plateCode,
    };
  }

  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      riskScore: json['riskScore'] as int,
      deviceStatus: json['deviceStatus'] as String,
      targetName: json['targetName'] as String,
      isSynced: json['isSynced'] as bool,
      isBlocked: json['isBlocked'] as bool,
      // Eski kayıtlarda 'plateCode' alanı yoksa null döner
      plateCode: json['plateCode'] as int?,
    );
  }

  CheckInRecord copyWith({
    String? id,
    String? timestamp,
    double? latitude,
    double? longitude,
    double? accuracy,
    int? riskScore,
    String? deviceStatus,
    String? targetName,
    bool? isSynced,
    bool? isBlocked,
    int? plateCode,
  }) {
    return CheckInRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      riskScore: riskScore ?? this.riskScore,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      targetName: targetName ?? this.targetName,
      isSynced: isSynced ?? this.isSynced,
      isBlocked: isBlocked ?? this.isBlocked,
      plateCode: plateCode ?? this.plateCode,
    );
  }
}

