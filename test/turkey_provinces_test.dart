import 'package:flutter_test/flutter_test.dart';
import 'package:waypoint_app/core/constants/turkey_provinces.dart';

void main() {
  group('TurkeyProvinces Dataset & Integrity Tests', () {
    test('Contains exactly 81 provinces of Turkey', () {
      expect(TurkeyProvinces.all.length, equals(81));
    });

    test('Plate codes are unique and cover range 1 to 81', () {
      final plateCodes = TurkeyProvinces.all.map((p) => p.plateCode).toSet();
      expect(plateCodes.length, equals(81));

      for (int i = 1; i <= 81; i++) {
        expect(plateCodes.contains(i), isTrue, reason: 'Missing plate code $i');
      }
    });

    test(
      'All province coordinates are valid within Turkey geographical boundaries',
      () {
        for (final province in TurkeyProvinces.all) {
          // Turkey Latitude is approx 35.8 to 42.2
          expect(
            province.latitude,
            inInclusiveRange(35.5, 42.5),
            reason:
                '${province.name} latitude out of bounds: ${province.latitude}',
          );

          // Turkey Longitude is approx 25.5 to 45.0
          expect(
            province.longitude,
            inInclusiveRange(25.0, 45.0),
            reason:
                '${province.name} longitude out of bounds: ${province.longitude}',
          );

          expect(province.name.isNotEmpty, isTrue);
          expect(province.defaultCheckpointName.isNotEmpty, isTrue);
          expect(province.region.isNotEmpty, isTrue);
          expect(province.formattedPlate.length, equals(2));
        }
      },
    );
  });

  group('TurkeyProvinces Nearest Province (Haversine) Tests', () {
    test('Finds Ankara when coordinates are in Ankara center', () {
      final nearest = TurkeyProvinces.findNearest(39.9334, 32.8597);
      expect(nearest.plateCode, equals(6));
      expect(nearest.name, equals('Ankara'));
    });

    test('Finds Istanbul when coordinates are in Kadikoy / Istanbul', () {
      final nearest = TurkeyProvinces.findNearest(40.9905, 29.0255);
      expect(nearest.plateCode, equals(34));
      expect(nearest.name, equals('İstanbul'));
    });

    test('Finds Izmir when coordinates are in Konak / Izmir', () {
      final nearest = TurkeyProvinces.findNearest(38.4192, 27.1287);
      expect(nearest.plateCode, equals(35));
      expect(nearest.name, equals('İzmir'));
    });

    test('Finds Antalya when coordinates are in Antalya center', () {
      final nearest = TurkeyProvinces.findNearest(36.8969, 30.7133);
      expect(nearest.plateCode, equals(7));
      expect(nearest.name, equals('Antalya'));
    });

    test('Finds Trabzon when coordinates are in Trabzon center', () {
      final nearest = TurkeyProvinces.findNearest(41.0027, 39.7168);
      expect(nearest.plateCode, equals(61));
      expect(nearest.name, equals('Trabzon'));
    });
  });

  group('TurkeyProvinces Search & Normalization Tests', () {
    test('Searches by exact plate code', () {
      final results = TurkeyProvinces.search('06');
      expect(results.any((p) => p.name == 'Ankara'), isTrue);

      final results34 = TurkeyProvinces.search('34');
      expect(results34.first.name, equals('İstanbul'));
    });

    test('Searches with Turkish case insensitivity', () {
      final izmirLower = TurkeyProvinces.search('izmir');
      expect(izmirLower.first.plateCode, equals(35));

      final izmirUpper = TurkeyProvinces.search('İZMİR');
      expect(izmirUpper.first.plateCode, equals(35));

      final istanbul = TurkeyProvinces.search('istanbul');
      expect(istanbul.first.plateCode, equals(34));

      final diyarbakir = TurkeyProvinces.search('diyarbakir');
      expect(diyarbakir.first.plateCode, equals(21));

      final eskisehir = TurkeyProvinces.search('eskisehir');
      expect(eskisehir.first.plateCode, equals(26));
    });

    test('Searches by checkpoint name', () {
      final results = TurkeyProvinces.search('Kızılay');
      expect(results.any((p) => p.name == 'Ankara'), isTrue);

      final konak = TurkeyProvinces.search('Saat Kulesi');
      expect(konak.any((p) => p.name == 'İzmir' || p.name == 'Çorum'), isTrue);
    });

    test('Returns all 81 provinces on empty query', () {
      final results = TurkeyProvinces.search('');
      expect(results.length, equals(81));
    });
  });
}
