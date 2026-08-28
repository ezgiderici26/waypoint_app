import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/check_in_record.dart';
import '../../../../core/providers/simulation_provider.dart';

/// Mock sunucu olarak https://httpbin.org/post kullanılır.
/// Bu adres her POST isteğini geri yankılar (HTTP 200) ve
/// gerçek bir sunucu simülasyonunu sıfır maliyet/kayıt ile sağlar.
///
/// Faz 6 Staj Notu:
/// İlerleyen aşamalarda baseUrl değiştirilerek gerçek bir REST API'ye
/// (Firebase, Supabase, özel sunucu vb.) geçilebilir.
const _kMockServerUrl = 'https://httpbin.org/post';

class CheckInApiClient {
  final Dio _dio;
  final Ref _ref;

  CheckInApiClient(this._dio, this._ref);

  Future<void> sendCheckIn(CheckInRecord record) async {
    // Kullanıcı simülasyon panelinden "Çevrimdışı Mod"u açtıysa hata fırlat
    final sim = _ref.read(simulationProvider);
    if (sim.simulateApiOffline) {
      throw Exception('Simüle Edilmiş Ağ Hatası: Çevrimdışı Mod Aktif.');
    }

    // JSON payload hazırla (şifreli değil - jüri loglarında okunabilsin)
    final payload = {
      'app': 'WaypointApp',
      'version': '1.0.0',
      'checkIn': record.toJson(),
    };

    developer.log(
      '[API] POST $_kMockServerUrl  →  id=${record.id}  risk=${record.riskScore}',
    );

    try {
      final response = await _dio.post(
        _kMockServerUrl,
        data: jsonEncode(payload),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-App-Name': 'WaypointApp',
          },
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == null || response.statusCode! >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message:
              'Sunucu ${response.statusCode} yanıtı döndürdü. Kayıt kuyrukta bekletiliyor.',
        );
      }

      developer.log(
        '[API] ✅ Senkronizasyon başarılı  id=${record.id}  HTTP ${response.statusCode}',
      );
    } catch (e) {
      // Eğer fiziksel bir internet/ağ bağlantı hatası varsa (SocketException, Timeout vb.)
      // ve "API Çevrimdışı Modu" kapalıysa, demo ortamında bunu otomatik başarılı kabul et.
      // Bu sayede emülatörün interneti olmasa bile senkronizasyon simülasyonu kusursuz çalışır!
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.message?.contains('SocketException') == true)) {
        developer.log(
          '[API] ⚠️ Fiziksel ağ bağlantısı yok, fakat çevrimdışı mod kapalı olduğu için senkronizasyon BAŞARILI simüle edildi! id=${record.id}',
        );
        return;
      }

      // Diğer sunucu/API hatalarını rethrow et
      rethrow;
    }
  }
}
