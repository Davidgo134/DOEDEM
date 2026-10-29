import '../core/models/track_point.dart';

/// Abstract contract for real-time tracking data source.
abstract class TrackingRepository {
  /// Stream of active trackpoints for a specific route.
  Stream<List<TrackPoint>> watchActivePoints(String routeId);

  /// Send a single real-time trackpoint.
  Future<void> sendTrackPoint(TrackPoint point);

  /// Send a batch of buffered points in chronological order.
  Future<void> sendBufferedPoints(List<TrackPoint> points);

  /// Indicates whether the active implementation is a local mock or real backend.
  bool get isMock;

  /// Dispose any active timers or streams.
  void dispose();
}
