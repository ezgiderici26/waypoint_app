import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SentNotificationLog {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'ENTER', 'EXIT', 'TEST', 'GENERAL'

  const SentNotificationLog({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  final List<SentNotificationLog> _history = [];
  List<SentNotificationLog> get history => List.unmodifiable(_history);

  static const String geofenceChannelId = 'geofence_alerts_channel';
  static const String geofenceChannelName = 'Geofence Bölge Uyarıları';
  static const String geofenceChannelDescription =
      'Hedef kontrol alanına giriş ve çıkış bildirimleri';

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      _isInitialized = true;
      return;
    }

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Bildirime tıklandı: ${response.payload}");
        },
      );

      // Create Android Notification Channel
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          geofenceChannelId,
          geofenceChannelName,
          description: geofenceChannelDescription,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint("NotificationService başlatma hatası: $e");
      _isInitialized = true; // Still allow app to continue gracefully
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String type = 'GENERAL',
  }) async {
    _history.insert(
      0,
      SentNotificationLog(
        id: id,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
      ),
    );

    if (kIsWeb || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          geofenceChannelId,
          geofenceChannelName,
          channelDescription: geofenceChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          ticker: 'Waypoint Geofence',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Bildirim gönderme hatası: $e");
    }
  }

  /// Geofence Entry Notification
  Future<void> showGeofenceEnterNotification(
    String targetName,
    double radiusMeters,
  ) async {
    await showNotification(
      id: 101,
      title: "📍 Hedef Alana Girdiniz!",
      body:
          "$targetName sınırları içindesiniz (${radiusMeters.toInt()}m yarıçap). Güvenli check-in yapabilirsiniz.",
      payload: 'GEOFENCE_ENTER',
      type: 'ENTER',
    );
  }

  /// Geofence Exit Notification
  Future<void> showGeofenceExitNotification(
    String targetName,
    double distanceMeters,
  ) async {
    await showNotification(
      id: 102,
      title: "🚪 Hedef Alandan Çıktınız",
      body:
          "$targetName bölgesinden uzaklaştınız. (Şu anki mesafe: ${distanceMeters.toInt()}m)",
      payload: 'GEOFENCE_EXIT',
      type: 'EXIT',
    );
  }

  /// Direct Test Notification
  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: "🛰️ Waypoint Sistem Bildirimi",
      body:
          "Arka plan bildirim servisi ve geofence tetikleyicisi başarıyla çalışıyor.",
      payload: 'TEST_NOTIFICATION',
      type: 'TEST',
    );
  }

  void clearHistory() {
    _history.clear();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
