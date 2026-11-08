import 'dart:async';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../core/models/track_point.dart';
import 'tracking_repository.dart';

/// In-memory mock tracking repository that simulates a vehicle moving along
/// the pilot route polyline. Works without network, permissions or backend.
class LocalMockRepository implements TrackingRepository {
  final List<LatLng> polyline;
  final bool enableSimulation;
  final StreamController<List<TrackPoint>> _controller = StreamController<List<TrackPoint>>.broadcast();
  final Map<String, TrackPoint> _dynamicPoints = {};
  Timer? _simulationTimer;

  int _currentSegmentIndex = 0;
  double _segmentProgress = 0.0; // 0.0 to 1.0
  bool _forward = true;

  static const List<LatLng> defaultRoutePolyline = [
    LatLng(48.7126, 44.5126), // Волгоград
    LatLng(48.8000, 44.4500),
    LatLng(49.3033, 43.9806), // Иловля
    LatLng(49.7800, 43.6500),
    LatLng(50.0600, 43.2370), // Михайловка
    LatLng(50.3520, 44.1680), // п. Реконструкция
  ];

  LocalMockRepository({
    List<LatLng>? customPolyline,
    this.enableSimulation = false,
  })  : polyline = (customPolyline != null && customPolyline.length >= 2)
            ? customPolyline
            : defaultRoutePolyline {
    if (enableSimulation) {
      _startSimulation();
    }
  }

  @override
  bool get isMock => enableSimulation;

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _advanceSimulation();
    });
    // Emit initial position immediately
    _advanceSimulation();
  }

  void _advanceSimulation() {
    if (polyline.length < 2) return;

    // Advance progress along the current segment
    _segmentProgress += 0.08;
    if (_segmentProgress >= 1.0) {
      _segmentProgress = 0.0;
      if (_forward) {
        _currentSegmentIndex++;
        if (_currentSegmentIndex >= polyline.length - 1) {
          _forward = false;
          _currentSegmentIndex = polyline.length - 2;
        }
      } else {
        _currentSegmentIndex--;
        if (_currentSegmentIndex < 0) {
          _forward = true;
          _currentSegmentIndex = 0;
        }
      }
    }

    final p1 = polyline[_currentSegmentIndex];
    final p2 = polyline[_currentSegmentIndex + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * _segmentProgress;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * _segmentProgress;

    final simulatedVehicle = TrackPoint(
      deviceId: 'simulated-driver-653',
      routeId: AppConstants.defaultRouteId,
      lat: lat,
      lng: lng,
      speed: 18.5, // ~66 km/h
      accuracy: 6.0,
      source: 'driver',
      ts: DateTime.now().toUtc(),
    );

    _dynamicPoints[simulatedVehicle.deviceId] = simulatedVehicle;
    _emitCurrentPoints();
  }

  void _emitCurrentPoints() {
    if (!_controller.isClosed) {
      _controller.add(_dynamicPoints.values.toList());
    }
  }

  @override
  Stream<List<TrackPoint>> watchActivePoints(String routeId) async* {
    yield _dynamicPoints.values.where((p) => p.routeId == routeId).toList();
    yield* _controller.stream.map(
      (list) => list.where((p) => p.routeId == routeId).toList(),
    );
  }

  @override
  Future<void> sendTrackPoint(TrackPoint point) async {
    _dynamicPoints[point.deviceId] = point;
    _emitCurrentPoints();
  }

  @override
  Future<void> sendBufferedPoints(List<TrackPoint> points) async {
    for (final p in points) {
      _dynamicPoints[p.deviceId] = p;
    }
    _emitCurrentPoints();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _controller.close();
  }
}
