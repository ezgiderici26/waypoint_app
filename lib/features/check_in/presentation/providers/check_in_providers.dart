import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/check_in_record.dart';
import '../../data/api/check_in_api_client.dart';
import '../../../../core/utils/encryption_helper.dart';

class CheckInHistoryNotifier extends StateNotifier<List<CheckInRecord>> {
  final CheckInApiClient _apiClient;
  late final Box _box;
  bool _isSyncing = false;
  Timer? _syncTimer;

  CheckInHistoryNotifier(this._apiClient) : super([]) {
    _initHive();
  }

  void _initHive() {
    _box = Hive.box('check_in_box');
    _loadRecords();

    // Start periodic sync worker to retry offline items every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => syncPendingRecords());
  }

  void _loadRecords() {
    final List<CheckInRecord> loaded = [];
    for (var key in _box.keys) {
      final dynamic raw = _box.get(key);
      if (raw != null) {
        try {
          if (raw is String) {
            // Decrypt AES encrypted record JSON string
            final decrypted = EncryptionHelper.decrypt(raw);
            final Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(decrypted));
            loaded.add(CheckInRecord.fromJson(json));
          } else if (raw is Map) {
            // Fallback for legacy plain text map structure
            final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
            loaded.add(CheckInRecord.fromJson(json));
          }
        } catch (e) {
          developer.log("Yerel kayıt okuma hatası: $e");
        }
      }
    }
    // Sort from newest to oldest
    loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = loaded;
  }

  Future<void> addCheckInRecord({
    required double latitude,
    required double longitude,
    required double accuracy,
    required int riskScore,
    required String deviceStatus,
    required String targetName,
    required bool isBlocked,
  }) async {
    final record = CheckInRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now().toIso8601String(),
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      riskScore: riskScore,
      deviceStatus: deviceStatus,
      targetName: targetName,
      isSynced: false,
      isBlocked: isBlocked,
    );

    // 1. Encrypt and Save to local database (Hive)
    final jsonString = jsonEncode(record.toJson());
    final encryptedData = EncryptionHelper.encrypt(jsonString);
    await _box.put(record.id, encryptedData);
    
    // 2. Reload history state to update UI instantly
    _loadRecords();

    // 3. Immediately attempt to sync this new record (and any other pending ones)
    await syncPendingRecords();
  }

  Future<bool> syncPendingRecords() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    bool allSuccess = true;

    try {
      final pending = state.where((record) => !record.isSynced).toList();
      if (pending.isEmpty) return true;

      for (var record in pending) {
        try {
          // Attempt HTTP POST via Client
          await _apiClient.sendCheckIn(record);

          // Success: update synced status in database (encrypting payload)
          final updated = record.copyWith(isSynced: true);
          final jsonString = jsonEncode(updated.toJson());
          final encryptedData = EncryptionHelper.encrypt(jsonString);
          await _box.put(record.id, encryptedData);

          developer.log("Check-in Eşitleme Başarılı (ID: ${record.id})");
        } catch (e) {
          allSuccess = false;
          // Keep isSynced as false for retry on next worker tick
          developer.log("Check-in Eşitleme Hatası (ID: ${record.id}): $e");
        }
      }
      
      // Reload updated records into UI state
      _loadRecords();
      return allSuccess;
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

// Providers declarations
final dioProvider = Provider<Dio>((ref) => Dio());

final apiClientProvider = Provider<CheckInApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return CheckInApiClient(dio, ref);
});

final checkInHistoryProvider = StateNotifierProvider<CheckInHistoryNotifier, List<CheckInRecord>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CheckInHistoryNotifier(apiClient);
});
