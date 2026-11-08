import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/route_data.dart';
import '../../core/models/track_point.dart';
import 'fallback_live_map.dart';
import 'live_map_view.dart';
import 'yandex_live_map.dart';

class MapKeyAvailableNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Enabled by default on Android devices (key is loaded by MainApplication)
    return true;
  }

  void forceEnableMap(bool enable) {
    state = enable;
  }
}

final mapKeyAvailableProvider =
    NotifierProvider<MapKeyAvailableNotifier, bool>(MapKeyAvailableNotifier.new);

/// LiveMap facade widget.
/// Isolates feature code entirely from Yandex MapKit.
/// Seamlessly falls back to FallbackLiveMap if API key is not present.
class LiveMap extends ConsumerWidget {
  final RouteData? route;
  final List<TrackPoint> activePoints;
  final TrackPoint? selectedPoint;
  final RouteStop? selectedStop;
  final VehicleTapCallback? onVehicleTap;
  final StopTapCallback? onStopTap;
  final void Function(LiveMapController controller)? onMapCreated;

  const LiveMap({
    super.key,
    required this.route,
    required this.activePoints,
    this.selectedPoint,
    this.selectedStop,
    this.onVehicleTap,
    this.onStopTap,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMapAvailable = ref.watch(mapKeyAvailableProvider);

    if (!isMapAvailable) {
      return FallbackLiveMap(
        route: route,
        activePoints: activePoints,
        selectedPoint: selectedPoint,
        onVehicleTap: onVehicleTap,
      );
    }

    return YandexLiveMap(
      route: route,
      activePoints: activePoints,
      selectedPoint: selectedPoint,
      selectedStop: selectedStop,
      onVehicleTap: onVehicleTap,
      onStopTap: onStopTap,
      onMapCreated: onMapCreated,
    );
  }
}
