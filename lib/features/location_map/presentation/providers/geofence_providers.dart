import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/location_data.dart';
import 'location_providers.dart';

enum GeofenceStatus { unknown, inside, outside }

class GeofenceEvent {
  final String type; // 'ENTER' or 'EXIT'
  final String targetName;
  final double distanceMeters;
  final DateTime timestamp;

  const GeofenceEvent({
    required this.type,
    required this.targetName,
    required this.distanceMeters,
    required this.timestamp,
  });
}

class GeofenceState {
  final GeofenceStatus status;
  final GeofenceEvent? lastEvent;
  final double? currentDistance;
  final String targetName;
  final double targetRadius;
  final bool notificationsEnabled;
  final List<GeofenceEvent> eventsHistory;

  const GeofenceState({
    required this.status,
    this.lastEvent,
    this.currentDistance,
    required this.targetName,
    required this.targetRadius,
    this.notificationsEnabled = true,
    this.eventsHistory = const [],
  });

  bool get isInside => status == GeofenceStatus.inside;

  factory GeofenceState.initial() {
    return const GeofenceState(
      status: GeofenceStatus.unknown,
      targetName: 'Kadıköy Meydan',
      targetRadius: 200.0,
      notificationsEnabled: true,
      eventsHistory: [],
    );
  }

  GeofenceState copyWith({
    GeofenceStatus? status,
    GeofenceEvent? lastEvent,
    double? currentDistance,
    String? targetName,
    double? targetRadius,
    bool? notificationsEnabled,
    List<GeofenceEvent>? eventsHistory,
  }) {
    return GeofenceState(
      status: status ?? this.status,
      lastEvent: lastEvent ?? this.lastEvent,
      currentDistance: currentDistance ?? this.currentDistance,
      targetName: targetName ?? this.targetName,
      targetRadius: targetRadius ?? this.targetRadius,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      eventsHistory: eventsHistory ?? this.eventsHistory,
    );
  }
}

class GeofenceNotifier extends StateNotifier<GeofenceState> {
  final Ref _ref;

  GeofenceNotifier(this._ref) : super(GeofenceState.initial()) {
    // 1. Listen to target location changes
    _ref.listen<TargetLocation>(targetLocationProvider, (_, nextTarget) {
      state = state.copyWith(
        targetName: nextTarget.name,
        targetRadius: nextTarget.radius,
      );
    });

    // 2. Listen to live/background location stream updates
    _ref.listen<AsyncValue<LocationData>>(locationStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((LocationData location) {
        _evaluateGeofence(location);
      });
    });
  }

  void _evaluateGeofence(LocationData userLocation) {
    final target = _ref.read(targetLocationProvider);
    final repo = _ref.read(locationRepositoryProvider);
    final notifService = _ref.read(notificationServiceProvider);

    final double distance = repo.calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      target.latitude,
      target.longitude,
    );

    final bool isNowInside = distance <= target.radius;
    final GeofenceStatus newStatus = isNowInside
        ? GeofenceStatus.inside
        : GeofenceStatus.outside;
    final GeofenceStatus previousStatus = state.status;

    // Check transition: ENTER
    if (newStatus == GeofenceStatus.inside &&
        previousStatus != GeofenceStatus.inside) {
      final event = GeofenceEvent(
        type: 'ENTER',
        targetName: target.name,
        distanceMeters: distance,
        timestamp: DateTime.now(),
      );

      if (state.notificationsEnabled) {
        notifService.showGeofenceEnterNotification(target.name, target.radius);
      }

      state = state.copyWith(
        status: GeofenceStatus.inside,
        currentDistance: distance,
        lastEvent: event,
        eventsHistory: [event, ...state.eventsHistory],
      );
    }
    // Check transition: EXIT
    else if (newStatus == GeofenceStatus.outside &&
        previousStatus == GeofenceStatus.inside) {
      final event = GeofenceEvent(
        type: 'EXIT',
        targetName: target.name,
        distanceMeters: distance,
        timestamp: DateTime.now(),
      );

      if (state.notificationsEnabled) {
        notifService.showGeofenceExitNotification(target.name, distance);
      }

      state = state.copyWith(
        status: GeofenceStatus.outside,
        currentDistance: distance,
        lastEvent: event,
        eventsHistory: [event, ...state.eventsHistory],
      );
    }
    // Update distance without status transition
    else {
      state = state.copyWith(status: newStatus, currentDistance: distance);
    }
  }

  /// Manually trigger Geofence Entry simulation
  Future<void> simulateGeofenceEnter() async {
    final target = _ref.read(targetLocationProvider);
    final notifService = _ref.read(notificationServiceProvider);

    final event = GeofenceEvent(
      type: 'ENTER',
      targetName: target.name,
      distanceMeters: 45.0, // Safely within 200m radius
      timestamp: DateTime.now(),
    );

    if (state.notificationsEnabled) {
      await notifService.showGeofenceEnterNotification(
        target.name,
        target.radius,
      );
    }

    state = state.copyWith(
      status: GeofenceStatus.inside,
      currentDistance: 45.0,
      lastEvent: event,
      eventsHistory: [event, ...state.eventsHistory],
    );
  }

  /// Manually trigger Geofence Exit simulation
  Future<void> simulateGeofenceExit() async {
    final target = _ref.read(targetLocationProvider);
    final notifService = _ref.read(notificationServiceProvider);

    final event = GeofenceEvent(
      type: 'EXIT',
      targetName: target.name,
      distanceMeters: 380.0, // Outside 200m radius
      timestamp: DateTime.now(),
    );

    if (state.notificationsEnabled) {
      await notifService.showGeofenceExitNotification(target.name, 380.0);
    }

    state = state.copyWith(
      status: GeofenceStatus.outside,
      currentDistance: 380.0,
      lastEvent: event,
      eventsHistory: [event, ...state.eventsHistory],
    );
  }

  void toggleNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void clearEvents() {
    state = state.copyWith(eventsHistory: []);
  }
}

final geofenceProvider = StateNotifierProvider<GeofenceNotifier, GeofenceState>(
  (ref) {
    return GeofenceNotifier(ref);
  },
);
