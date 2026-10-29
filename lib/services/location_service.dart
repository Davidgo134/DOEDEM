import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import '../core/models/track_point.dart';

enum GpsSignalStatus {
  searching,
  ok,
  noSignal,
  disabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastSentTime;
  double _lastKnownSpeed = 0.0;

  /// Checks current location permissions without requesting.
  Future<LocationPermission> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }
    return Geolocator.checkPermission();
  }

  /// Requests location permissions.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Opens app settings if permission is denied forever.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Opens location service settings if GPS is disabled.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Starts listening to GPS position updates and emits filtered trackpoints
  /// according to Decision 7:
  /// - Moving (> 1 m/s): every 10 seconds
  /// - Stationary (<= 1 m/s): every 30 seconds
  /// - LocationAccuracy.high, distanceFilter: 10m
  Stream<TrackPoint> startPositionStream({
    required String deviceId,
    required String routeId,
    required String source,
    void Function(GpsSignalStatus status)? onStatusChanged,
  }) {
    final controller = StreamController<TrackPoint>.broadcast();

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: AppConstants.locationDistanceFilterMeters,
      forceLocationManager: false,
      intervalDuration: const Duration(seconds: 5),
    );

    _positionSubscription?.cancel();
    _lastSentTime = null;

    onStatusChanged?.call(GpsSignalStatus.searching);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        onStatusChanged?.call(GpsSignalStatus.ok);

        final now = DateTime.now().toUtc();
        final speed = position.speed >= 0 ? position.speed : 0.0;
        _lastKnownSpeed = speed;

        final isMoving = speed > AppConstants.movingSpeedThresholdMps;
        final requiredInterval = isMoving
            ? AppConstants.movingIntervalSeconds
            : AppConstants.stationaryIntervalSeconds;

        final shouldSend = _lastSentTime == null ||
            now.difference(_lastSentTime!).inSeconds >= requiredInterval;

        if (shouldSend) {
          _lastSentTime = now;
          final point = TrackPoint(
            deviceId: deviceId,
            routeId: routeId,
            lat: position.latitude,
            lng: position.longitude,
            speed: speed,
            accuracy: position.accuracy,
            source: source,
            ts: now,
          );
          controller.add(point);
        }
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
        onStatusChanged?.call(GpsSignalStatus.noSignal);
      },
    );

    controller.onCancel = () {
      _positionSubscription?.cancel();
      _positionSubscription = null;
    };

    return controller.stream;
  }

  void stop() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  double get lastKnownSpeed => _lastKnownSpeed;
}
