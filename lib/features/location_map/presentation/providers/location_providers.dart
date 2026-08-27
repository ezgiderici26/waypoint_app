import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/repositories/location_repository.dart';
import '../../data/repositories/location_repository_impl.dart';

// Provide LocationRepository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return const LocationRepositoryImpl();
});

// Permission state representation
enum PermissionState { checking, denied, deniedForever, whileInUse, always }

// Manage permission state
class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier() : super(PermissionState.checking) {
    checkCurrentPermission();
  }

  Future<void> checkCurrentPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = PermissionState.denied;
      return;
    }

    final LocationPermission permission = await Geolocator.checkPermission();
    state = _mapPermissionToState(permission);
  }

  Future<void> requestWhileInUsePermission() async {
    final LocationPermission permission = await Geolocator.requestPermission();
    state = _mapPermissionToState(permission);
  }

  Future<void> requestAlwaysPermission() async {
    // Note: To request background (Always) permission on Android,
    // "while in use" permission must be granted first.
    final LocationPermission permission = await Geolocator.requestPermission();
    state = _mapPermissionToState(permission);
  }

  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  PermissionState _mapPermissionToState(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return PermissionState.denied;
      case LocationPermission.deniedForever:
        return PermissionState.deniedForever;
      case LocationPermission.whileInUse:
        return PermissionState.whileInUse;
      case LocationPermission.always:
        return PermissionState.always;
      default:
        return PermissionState.denied;
    }
  }
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
      return PermissionNotifier();
    });

// Custom simulated/overridden location state (for testing or instant province teleport)
final simulatedUserLocationProvider = StateProvider<LocationData?>((ref) => null);

// Provide Live Location Stream (with simulation override support)
final locationStreamProvider = StreamProvider<LocationData>((ref) async* {
  final simulatedLoc = ref.watch(simulatedUserLocationProvider);
  if (simulatedLoc != null) {
    yield simulatedLoc;
    return;
  }

  final repository = ref.watch(locationRepositoryProvider);
  final permission = ref.watch(permissionProvider);

  // Only stream location if permission is granted
  if (permission == PermissionState.whileInUse ||
      permission == PermissionState.always) {
    yield* repository.getLocationStream();
  } else {
    yield* const Stream.empty();
  }
});

// Geofence target coordinate state
class TargetLocation {
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // meters

  const TargetLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
}

// Provide target geofence location (default: 34 İstanbul)
final targetLocationProvider = StateProvider<TargetLocation>((ref) {
  return const TargetLocation(
    name: "34 İstanbul (Taksim Meydanı)",
    latitude: 41.0370,
    longitude: 28.9850,
    radius: 200.0,
  );
});

// Provide computed distance to target
final distanceToTargetProvider = Provider<double?>((ref) {
  final locationAsync = ref.watch(locationStreamProvider);
  final target = ref.watch(targetLocationProvider);
  final repository = ref.watch(locationRepositoryProvider);

  return locationAsync.maybeWhen(
    data: (LocationData data) {
      return repository.calculateDistance(
        data.latitude,
        data.longitude,
        target.latitude,
        target.longitude,
      );
    },
    orElse: () => null,
  );
});
