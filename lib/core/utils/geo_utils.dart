import 'package:latlong2/latlong.dart';

import '../../app/strings.dart';
import '../constants.dart';
import '../models/track_point.dart';

class GeoUtils {
  static const Distance _distance = Distance();

  /// Calculates geodesic distance between two points in meters.
  static double distanceMeters(LatLng p1, LatLng p2) {
    return _distance.as(LengthUnit.Meter, p1, p2);
  }

  /// Checks if a trackpoint was recorded more than 90 seconds ago (stale).
  static bool isPointStale(TrackPoint point, [DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    final diff = current.difference(point.ts.toUtc()).inSeconds;
    return diff > AppConstants.staleMarkerThresholdSeconds;
  }

  /// Checks if a trackpoint was recorded more than 10 minutes ago (hidden).
  static bool isPointExpired(TrackPoint point, [DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    final diff = current.difference(point.ts.toUtc()).inSeconds;
    return diff > AppConstants.hideMarkerThresholdSeconds;
  }

  /// Human-readable Russian time ago string for tooltips.
  static String formatPointAge(TrackPoint point, [DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    final diffSeconds = current.difference(point.ts.toUtc()).inSeconds;

    if (diffSeconds < 5) {
      return AppStrings.passengerUpdatedJustNow;
    } else if (diffSeconds < 60) {
      return AppStrings.passengerUpdatedSecAgo.replaceFirst('%s', '$diffSeconds');
    } else {
      final minutes = diffSeconds ~/ 60;
      return AppStrings.passengerUpdatedMinAgo.replaceFirst('%s', '$minutes');
    }
  }
}
