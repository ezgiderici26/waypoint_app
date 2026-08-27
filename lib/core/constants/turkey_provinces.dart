import 'dart:math';

/// Representation of a Turkish Province with geographic center and default checkpoint.
class TurkeyProvince {
  final int plateCode;
  final String name;
  final double latitude;
  final double longitude;
  final String defaultCheckpointName;
  final String region;

  const TurkeyProvince({
    required this.plateCode,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.defaultCheckpointName,
    required this.region,
  });

  /// Formatted plate code as string with leading zero if needed, e.g. "06", "34".
  String get formattedPlate => plateCode.toString().padLeft(2, '0');

  /// Distance in meters from a given latitude/longitude using Haversine formula.
  double distanceFrom(double lat, double lon) {
    const double earthRadiusMeters = 6371000;
    final dLat = _deg2rad(latitude - lat);
    final dLon = _deg2rad(longitude - lon);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat)) *
            cos(_deg2rad(latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);
}

/// Master dataset and utilities for all 81 Provinces of Turkey.
class TurkeyProvinces {
  TurkeyProvinces._();

  /// Comprehensive list of all 81 provinces of Turkey.
  static const List<TurkeyProvince> all = [
    TurkeyProvince(
      plateCode: 1,
      name: 'Adana',
      latitude: 37.0000,
      longitude: 35.3213,
      defaultCheckpointName: 'Seyhan Merkez',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 2,
      name: 'Adıyaman',
      latitude: 37.7648,
      longitude: 38.2786,
      defaultCheckpointName: 'Hükümet Meydanı',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 3,
      name: 'Afyonkarahisar',
      latitude: 38.7507,
      longitude: 30.5567,
      defaultCheckpointName: 'Zafer Meydanı',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 4,
      name: 'Ağrı',
      latitude: 39.7191,
      longitude: 43.0503,
      defaultCheckpointName: 'Cumhuriyet Caddesi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 5,
      name: 'Amasya',
      latitude: 40.6501,
      longitude: 35.8353,
      defaultCheckpointName: 'Yavuz Selim Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 6,
      name: 'Ankara',
      latitude: 39.9334,
      longitude: 32.8597,
      defaultCheckpointName: 'Kızılay Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 7,
      name: 'Antalya',
      latitude: 36.8969,
      longitude: 30.7133,
      defaultCheckpointName: 'Muratpaşa Meydanı',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 8,
      name: 'Artvin',
      latitude: 41.1828,
      longitude: 41.8183,
      defaultCheckpointName: 'Valilik Önü',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 9,
      name: 'Aydın',
      latitude: 37.8560,
      longitude: 27.8416,
      defaultCheckpointName: 'Atatürk Meydanı',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 10,
      name: 'Balıkesir',
      latitude: 39.6484,
      longitude: 27.8826,
      defaultCheckpointName: 'Ali Hikmet Paşa Meydanı',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 11,
      name: 'Bilecik',
      latitude: 40.1451,
      longitude: 29.9799,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 12,
      name: 'Bingöl',
      latitude: 38.8854,
      longitude: 40.4983,
      defaultCheckpointName: 'Genç Caddesi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 13,
      name: 'Bitlis',
      latitude: 38.4006,
      longitude: 42.1095,
      defaultCheckpointName: 'Ulu Cami Çevresi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 14,
      name: 'Bolu',
      latitude: 40.7350,
      longitude: 31.6061,
      defaultCheckpointName: 'İzzet Baysal Caddesi',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 15,
      name: 'Burdur',
      latitude: 37.7203,
      longitude: 30.2908,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 16,
      name: 'Bursa',
      latitude: 40.1885,
      longitude: 29.0610,
      defaultCheckpointName: 'Heykel Kent Meydanı',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 17,
      name: 'Çanakkale',
      latitude: 40.1553,
      longitude: 26.4142,
      defaultCheckpointName: 'Kordon İskele',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 18,
      name: 'Çankırı',
      latitude: 40.6013,
      longitude: 33.6134,
      defaultCheckpointName: 'Belediye Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 19,
      name: 'Çorum',
      latitude: 40.5506,
      longitude: 34.9556,
      defaultCheckpointName: 'Saat Kulesi Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 20,
      name: 'Denizli',
      latitude: 37.7765,
      longitude: 29.0864,
      defaultCheckpointName: 'Delikliçınar Meydanı',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 21,
      name: 'Diyarbakır',
      latitude: 37.9144,
      longitude: 40.2306,
      defaultCheckpointName: 'Dağkapı Meydanı',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 22,
      name: 'Edirne',
      latitude: 41.6772,
      longitude: 26.5557,
      defaultCheckpointName: 'Saraçlar Caddesi',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 23,
      name: 'Elazığ',
      latitude: 38.6810,
      longitude: 39.2264,
      defaultCheckpointName: 'Gazi Caddesi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 24,
      name: 'Erzincan',
      latitude: 39.7500,
      longitude: 39.5000,
      defaultCheckpointName: 'Dörtyol Meydanı',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 25,
      name: 'Erzurum',
      latitude: 39.9043,
      longitude: 41.2679,
      defaultCheckpointName: 'Havuzbaşı Meydanı',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 26,
      name: 'Eskişehir',
      latitude: 39.7767,
      longitude: 30.5206,
      defaultCheckpointName: 'Odunpazarı Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 27,
      name: 'Gaziantep',
      latitude: 37.0662,
      longitude: 37.3833,
      defaultCheckpointName: 'Demokrasi Meydanı',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 28,
      name: 'Giresun',
      latitude: 40.9128,
      longitude: 38.3895,
      defaultCheckpointName: 'Atatürk Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 29,
      name: 'Gümüşhane',
      latitude: 40.4600,
      longitude: 39.4700,
      defaultCheckpointName: 'Zafer Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 30,
      name: 'Hakkâri',
      latitude: 37.5833,
      longitude: 43.7333,
      defaultCheckpointName: 'Bulvar Caddesi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 31,
      name: 'Hatay',
      latitude: 36.2023,
      longitude: 36.1606,
      defaultCheckpointName: 'Antakya Köprübaşı',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 32,
      name: 'Isparta',
      latitude: 37.7648,
      longitude: 30.5566,
      defaultCheckpointName: 'Kaymakkapı Meydanı',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 33,
      name: 'Mersin',
      latitude: 36.8121,
      longitude: 34.6415,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 34,
      name: 'İstanbul',
      latitude: 41.0082,
      longitude: 28.9784,
      defaultCheckpointName: 'Kadıköy Rıhtım Meydanı',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 35,
      name: 'İzmir',
      latitude: 38.4192,
      longitude: 27.1287,
      defaultCheckpointName: 'Konak Saat Kulesi',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 36,
      name: 'Kars',
      latitude: 40.6167,
      longitude: 43.1000,
      defaultCheckpointName: 'Faikbey Caddesi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 37,
      name: 'Kastamonu',
      latitude: 41.3887,
      longitude: 33.7827,
      defaultCheckpointName: 'Nasrullah Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 38,
      name: 'Kayseri',
      latitude: 38.7312,
      longitude: 35.4787,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 39,
      name: 'Kırklareli',
      latitude: 41.7333,
      longitude: 27.2167,
      defaultCheckpointName: 'Vilayet Meydanı',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 40,
      name: 'Kırşehir',
      latitude: 39.1425,
      longitude: 34.1709,
      defaultCheckpointName: 'Ahi Evran Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 41,
      name: 'Kocaeli',
      latitude: 40.7654,
      longitude: 29.9408,
      defaultCheckpointName: 'İzmit Yürüyüş Yolu',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 42,
      name: 'Konya',
      latitude: 37.8746,
      longitude: 32.4932,
      defaultCheckpointName: 'Alaaddin Tepesi Çevresi',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 43,
      name: 'Kütahya',
      latitude: 39.4167,
      longitude: 29.9833,
      defaultCheckpointName: 'Zafer Meydanı',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 44,
      name: 'Malatya',
      latitude: 38.3552,
      longitude: 38.3095,
      defaultCheckpointName: 'Soykan Meydanı',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 45,
      name: 'Manisa',
      latitude: 38.6191,
      longitude: 27.4289,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 46,
      name: 'Kahramanmaraş',
      latitude: 37.5858,
      longitude: 36.9371,
      defaultCheckpointName: 'Trabzon Caddesi',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 47,
      name: 'Mardin',
      latitude: 37.3212,
      longitude: 40.7245,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 48,
      name: 'Muğla',
      latitude: 37.2153,
      longitude: 28.3636,
      defaultCheckpointName: 'Kurşunlu Meydanı',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 49,
      name: 'Muş',
      latitude: 38.7432,
      longitude: 41.5064,
      defaultCheckpointName: 'İstasyon Caddesi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 50,
      name: 'Nevşehir',
      latitude: 38.6244,
      longitude: 34.7144,
      defaultCheckpointName: 'Atatürk Bulvarı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 51,
      name: 'Niğde',
      latitude: 37.9667,
      longitude: 34.6833,
      defaultCheckpointName: 'Ömer Halisdemir Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 52,
      name: 'Ordu',
      latitude: 40.9839,
      longitude: 37.8764,
      defaultCheckpointName: 'İlkadım Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 53,
      name: 'Rize',
      latitude: 41.0201,
      longitude: 40.5234,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 54,
      name: 'Sakarya',
      latitude: 40.7569,
      longitude: 30.3783,
      defaultCheckpointName: 'Adapazarı Kent Meydanı',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 55,
      name: 'Samsun',
      latitude: 41.2867,
      longitude: 36.3300,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 56,
      name: 'Siirt',
      latitude: 37.9333,
      longitude: 41.9500,
      defaultCheckpointName: 'Güres Caddesi',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 57,
      name: 'Sinop',
      latitude: 42.0231,
      longitude: 35.1531,
      defaultCheckpointName: 'İskele Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 58,
      name: 'Sivas',
      latitude: 39.7477,
      longitude: 37.0179,
      defaultCheckpointName: 'Kent Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 59,
      name: 'Tekirdağ',
      latitude: 40.9833,
      longitude: 27.5167,
      defaultCheckpointName: 'Hasan Ali Yücel Meydanı',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 60,
      name: 'Tokat',
      latitude: 40.3167,
      longitude: 36.5500,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 61,
      name: 'Trabzon',
      latitude: 41.0027,
      longitude: 39.7168,
      defaultCheckpointName: 'Meydan Parkı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 62,
      name: 'Tunceli',
      latitude: 39.1079,
      longitude: 39.5401,
      defaultCheckpointName: 'Seyit Rıza Meydanı',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 63,
      name: 'Şanlıurfa',
      latitude: 37.1591,
      longitude: 38.7969,
      defaultCheckpointName: 'Balıklıgöl Çevresi',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 64,
      name: 'Uşak',
      latitude: 38.6823,
      longitude: 29.4082,
      defaultCheckpointName: 'İsmetpaşa Caddesi',
      region: 'Ege',
    ),
    TurkeyProvince(
      plateCode: 65,
      name: 'Van',
      latitude: 38.4891,
      longitude: 43.4089,
      defaultCheckpointName: 'Cumhuriyet Caddesi',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 66,
      name: 'Yozgat',
      latitude: 39.8181,
      longitude: 34.8147,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 67,
      name: 'Zonguldak',
      latitude: 41.4564,
      longitude: 31.7987,
      defaultCheckpointName: 'Madenci Anıtı Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 68,
      name: 'Aksaray',
      latitude: 38.3687,
      longitude: 34.0370,
      defaultCheckpointName: '15 Temmuz Milli İrade Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 69,
      name: 'Bayburt',
      latitude: 40.2552,
      longitude: 40.2249,
      defaultCheckpointName: 'Saat Kulesi Meydanı',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 70,
      name: 'Karaman',
      latitude: 37.1759,
      longitude: 33.2287,
      defaultCheckpointName: 'Aktekke Kent Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 71,
      name: 'Kırıkkale',
      latitude: 39.8468,
      longitude: 33.5153,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'İç Anadolu',
    ),
    TurkeyProvince(
      plateCode: 72,
      name: 'Batman',
      latitude: 37.8812,
      longitude: 41.1293,
      defaultCheckpointName: 'Turgut Özal Bulvarı',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 73,
      name: 'Şırnak',
      latitude: 37.5164,
      longitude: 42.4594,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 74,
      name: 'Bartın',
      latitude: 41.6344,
      longitude: 32.3375,
      defaultCheckpointName: 'Hükümet Caddesi',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 75,
      name: 'Ardahan',
      latitude: 41.1105,
      longitude: 42.7022,
      defaultCheckpointName: 'Milli Egemenlik Parkı',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 76,
      name: 'Iğdır',
      latitude: 39.9196,
      longitude: 44.0450,
      defaultCheckpointName: 'Zübeyde Hanım Bulvarı',
      region: 'Doğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 77,
      name: 'Yalova',
      latitude: 40.6500,
      longitude: 29.2667,
      defaultCheckpointName: 'Cumhuriyet Meydanı & İskele',
      region: 'Marmara',
    ),
    TurkeyProvince(
      plateCode: 78,
      name: 'Karabük',
      latitude: 41.2061,
      longitude: 32.6204,
      defaultCheckpointName: 'Kemal Güneş Caddesi',
      region: 'Karadeniz',
    ),
    TurkeyProvince(
      plateCode: 79,
      name: 'Kilis',
      latitude: 36.7184,
      longitude: 37.1212,
      defaultCheckpointName: 'Cumhuriyet Meydanı',
      region: 'Güneydoğu Anadolu',
    ),
    TurkeyProvince(
      plateCode: 80,
      name: 'Osmaniye',
      latitude: 37.0742,
      longitude: 36.2478,
      defaultCheckpointName: 'Devlet Bahçeli Meydanı',
      region: 'Akdeniz',
    ),
    TurkeyProvince(
      plateCode: 81,
      name: 'Düzce',
      latitude: 40.8438,
      longitude: 31.1565,
      defaultCheckpointName: 'Anıtpark Meydanı',
      region: 'Karadeniz',
    ),
  ];

  /// Default province fallback (34 - Istanbul)
  static TurkeyProvince get defaultProvince => all[33]; // Plate 34

  /// Finds the geographically nearest province to the provided GPS coordinates.
  static TurkeyProvince findNearest(double latitude, double longitude) {
    TurkeyProvince nearest = all.first;
    double minDistance = double.infinity;

    for (final province in all) {
      final distance = province.distanceFrom(latitude, longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = province;
      }
    }
    return nearest;
  }

  /// Finds a province by its plate code (1-81).
  static TurkeyProvince? getByPlateCode(int plateCode) {
    try {
      return all.firstWhere((p) => p.plateCode == plateCode);
    } catch (_) {
      return null;
    }
  }

  /// Searches provinces by plate code (e.g. "06", "6", "34") or name (case-insensitive & Turkish aware).
  static List<TurkeyProvince> search(String query) {
    final cleanQuery = _normalizeTurkish(query.trim());
    if (cleanQuery.isEmpty) return all;

    // Check if query is plate number
    final int? plateNum = int.tryParse(cleanQuery);
    if (plateNum != null) {
      final matches = all
          .where(
            (p) =>
                p.plateCode == plateNum ||
                p.formattedPlate.startsWith(cleanQuery),
          )
          .toList();
      if (matches.isNotEmpty) return matches;
    }

    return all.where((p) {
      final normName = _normalizeTurkish(p.name);
      final normCheck = _normalizeTurkish(p.defaultCheckpointName);
      final normRegion = _normalizeTurkish(p.region);
      return normName.contains(cleanQuery) ||
          normCheck.contains(cleanQuery) ||
          normRegion.contains(cleanQuery) ||
          p.formattedPlate.contains(cleanQuery);
    }).toList();
  }

  /// Normalizes Turkish characters to lowercase ascii for accurate searching.
  static String _normalizeTurkish(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
  }
}
