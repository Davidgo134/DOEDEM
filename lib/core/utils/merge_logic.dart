import 'package:latlong2/latlong.dart';

import '../constants.dart';
import '../models/track_point.dart';
import 'geo_utils.dart';

/// Pure Dart merging and filtering algorithm for crowdsourced vehicle markers.
/// Implements Decision 9 and Decision 6:
/// 1. Discard points older than 10 minutes (600s).
/// 2. Deduplicate per deviceId: keep only the newest point.
/// 3. Group by routeId.
/// 4. If a driver point and passenger points are within 150m and within 60s of each other,
///    merge them into ONE marker, preferring the driver point.
/// 5. If multiple passenger points are within 150m and within 60s of each other,
///    merge them into ONE marker (preferring the newest passenger point).
List<TrackPoint> mergeTrackPoints(List<TrackPoint> rawPoints, {DateTime? now}) {
  final currentTime = (now ?? DateTime.now()).toUtc();

  // 1. Filter out expired points (> 10 minutes old)
  final validPoints = rawPoints.where((p) {
    return !GeoUtils.isPointExpired(p, currentTime);
  }).toList();

  if (validPoints.isEmpty) return [];

  // 2. Per source device, keep only the newest point
  final Map<String, TrackPoint> newestPerDevice = {};
  for (final point in validPoints) {
    final existing = newestPerDevice[point.deviceId];
    if (existing == null || point.ts.isAfter(existing.ts)) {
      newestPerDevice[point.deviceId] = point;
    }
  }

  // 3. Group by routeId
  final Map<String, List<TrackPoint>> byRoute = {};
  for (final point in newestPerDevice.values) {
    byRoute.putIfAbsent(point.routeId, () => []).add(point);
  }

  final List<TrackPoint> result = [];

  for (final routePoints in byRoute.values) {
    // Separate drivers and passengers
    final drivers = routePoints.where((p) => p.isDriver).toList();
    final passengers = routePoints.where((p) => p.isPassenger).toList();

    // Drivers always show up
    result.addAll(drivers);

    // Track which passenger points have been absorbed
    final Set<String> absorbedPassengerDeviceIds = {};

    // 4. Absorb passenger points that are near a driver point (<= 150m and <= 60s)
    for (final passenger in passengers) {
      final passengerLatLng = LatLng(passenger.lat, passenger.lng);

      for (final driver in drivers) {
        final driverLatLng = LatLng(driver.lat, driver.lng);
        final dist = GeoUtils.distanceMeters(passengerLatLng, driverLatLng);
        final timeDiff = (driver.ts.difference(passenger.ts).inSeconds).abs();

        if (dist <= AppConstants.mergeMaxDistanceMeters &&
            timeDiff <= AppConstants.mergeMaxTimeDiffSeconds) {
          absorbedPassengerDeviceIds.add(passenger.deviceId);
          break; // Absorbed into driver
        }
      }
    }

    // Remaining passenger points not near any driver
    final remainingPassengers = passengers
        .where((p) => !absorbedPassengerDeviceIds.contains(p.deviceId))
        .toList();

    // Sort remaining passengers newest first
    remainingPassengers.sort((a, b) => b.ts.compareTo(a.ts));

    // 5. Cluster nearby remaining passenger points (<= 150m and <= 60s)
    final List<TrackPoint> mergedPassengers = [];
    for (final passenger in remainingPassengers) {
      bool mergedWithExisting = false;
      final pLatLng = LatLng(passenger.lat, passenger.lng);

      for (final clusterLeader in mergedPassengers) {
        final leaderLatLng = LatLng(clusterLeader.lat, clusterLeader.lng);
        final dist = GeoUtils.distanceMeters(pLatLng, leaderLatLng);
        final timeDiff = (clusterLeader.ts.difference(passenger.ts).inSeconds).abs();

        if (dist <= AppConstants.mergeMaxDistanceMeters &&
            timeDiff <= AppConstants.mergeMaxTimeDiffSeconds) {
          mergedWithExisting = true;
          break;
        }
      }

      if (!mergedWithExisting) {
        mergedPassengers.add(passenger);
      }
    }

    result.addAll(mergedPassengers);
  }

  return result;
}
