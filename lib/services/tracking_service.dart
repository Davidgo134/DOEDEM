import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../app/strings.dart';
import '../core/constants.dart';
import '../core/models/track_point.dart';
import '../core/utils/preferences_service.dart';
import '../data/tracking_repository_provider.dart';
import 'foreground_service.dart';
import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final foregroundServiceProvider = Provider<ForegroundService>((ref) => ForegroundService());

class TrackingState {
  final bool isTracking;
  final String? activeSource; // 'driver' or 'passenger'
  final GpsSignalStatus gpsStatus;
  final int bufferedPointsCount;
  final TrackPoint? lastRecordedPoint;

  const TrackingState({
    required this.isTracking,
    this.activeSource,
    this.gpsStatus = GpsSignalStatus.searching,
    this.bufferedPointsCount = 0,
    this.lastRecordedPoint,
  });

  TrackingState copyWith({
    bool? isTracking,
    String? activeSource,
    GpsSignalStatus? gpsStatus,
    int? bufferedPointsCount,
    TrackPoint? lastRecordedPoint,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      activeSource: activeSource ?? this.activeSource,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      bufferedPointsCount: bufferedPointsCount ?? this.bufferedPointsCount,
      lastRecordedPoint: lastRecordedPoint ?? this.lastRecordedPoint,
    );
  }
}

final trackingServiceProvider =
    NotifierProvider<TrackingServiceNotifier, TrackingState>(TrackingServiceNotifier.new);

class TrackingServiceNotifier extends Notifier<TrackingState> {
  StreamSubscription<TrackPoint>? _positionSub;

  @override
  TrackingState build() {
    ref.onDispose(() {
      _positionSub?.cancel();
    });
    return const TrackingState(isTracking: false);
  }

  Future<bool> startTracking({
    required String source,
    String routeId = AppConstants.defaultRouteId,
  }) async {
    final prefsService = ref.read(preferencesServiceProvider);
    final locationService = ref.read(locationServiceProvider);
    final foregroundService = ref.read(foregroundServiceProvider);
    final repository = ref.read(trackingRepositoryProvider);

    // 1. Consent check (Russian consent required)
    if (!prefsService.hasLocationConsent()) {
      return false;
    }

    // 2. Permission check
    LocationPermission permission = await locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await locationService.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(gpsStatus: GpsSignalStatus.permissionDeniedForever);
      return false;
    }

    if (permission == LocationPermission.denied) {
      state = state.copyWith(gpsStatus: GpsSignalStatus.permissionDenied);
      return false;
    }

    // 3. Start foreground notification service
    final notifTitle = source == 'driver'
        ? AppStrings.driverShiftActiveNotification
        : AppStrings.passengerReporterActiveNotification;
    final notifBody = AppStrings.driverShiftNotificationBody;

    await foregroundService.start(title: notifTitle, body: notifBody);

    // 4. Start position stream
    final deviceId = prefsService.getOrCreateDeviceId();
    _positionSub?.cancel();

    _positionSub = locationService.startPositionStream(
      deviceId: deviceId,
      routeId: routeId,
      source: source,
      onStatusChanged: (status) {
        state = state.copyWith(gpsStatus: status);
      },
    ).listen(
      (point) async {
        state = state.copyWith(
          lastRecordedPoint: point,
          gpsStatus: GpsSignalStatus.ok,
        );

        try {
          await repository.sendTrackPoint(point);
        } catch (e) {
          debugPrint('Error sending trackpoint to repository: $e');
        }
      },
      onError: (err) {
        state = state.copyWith(gpsStatus: GpsSignalStatus.noSignal);
      },
    );

    state = state.copyWith(
      isTracking: true,
      activeSource: source,
      gpsStatus: GpsSignalStatus.ok,
    );

    return true;
  }

  Future<void> stopTracking() async {
    final locationService = ref.read(locationServiceProvider);
    final foregroundService = ref.read(foregroundServiceProvider);

    _positionSub?.cancel();
    _positionSub = null;
    locationService.stop();
    await foregroundService.stop();

    state = state.copyWith(
      isTracking: false,
      activeSource: null,
      gpsStatus: GpsSignalStatus.searching,
    );
  }

  void updateBufferedCount(int count) {
    state = state.copyWith(bufferedPointsCount: count);
  }
}
