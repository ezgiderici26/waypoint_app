import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/turkey_provinces.dart';
import '../../domain/entities/location_data.dart';
import 'location_providers.dart';

class SelectedProvinceNotifier extends StateNotifier<TurkeyProvince> {
  final Ref ref;

  SelectedProvinceNotifier(this.ref) : super(TurkeyProvinces.defaultProvince);

  /// Selects a new province and automatically updates the active Geofence target location AND user position.
  void selectProvince(TurkeyProvince province, {bool moveUserToProvince = true}) {
    state = province;

    ref.read(targetLocationProvider.notifier).state = TargetLocation(
      name: "${province.formattedPlate} ${province.name} (${province.defaultCheckpointName})",
      latitude: province.latitude,
      longitude: province.longitude,
      radius: 200.0,
    );

    if (moveUserToProvince) {
      ref.read(simulatedUserLocationProvider.notifier).state = LocationData(
        latitude: province.latitude,
        longitude: province.longitude,
        speed: 0.0,
        accuracy: 4.5,
        bearing: 0.0,
        timestamp: DateTime.now(),
        isMocked: false,
      );
    }
  }

  /// Reset to live real GPS sensor hardware
  void useRealGps() {
    ref.read(simulatedUserLocationProvider.notifier).state = null;
  }

  /// Automatically finds and selects the nearest province based on live GPS coordinates.
  TurkeyProvince autoDetectNearest(LocationData userLocation) {
    final nearest = TurkeyProvinces.findNearest(
      userLocation.latitude,
      userLocation.longitude,
    );
    selectProvince(nearest, moveUserToProvince: false);
    return nearest;
  }
}

/// Provider managing the actively selected Turkish province across the entire application.
final selectedProvinceProvider =
    StateNotifierProvider<SelectedProvinceNotifier, TurkeyProvince>((ref) {
      return SelectedProvinceNotifier(ref);
    });

/// Provider indicating whether the user is currently located in the same province as the selected province.
final isUserInSelectedProvinceProvider = Provider<bool>((ref) {
  final locationAsync = ref.watch(locationStreamProvider);
  final selected = ref.watch(selectedProvinceProvider);

  return locationAsync.maybeWhen(
    data: (userLoc) {
      final nearest = TurkeyProvinces.findNearest(
        userLoc.latitude,
        userLoc.longitude,
      );
      return nearest.plateCode == selected.plateCode;
    },
    orElse: () => false,
  );
});
