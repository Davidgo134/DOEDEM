import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marshrutka/core/constants.dart';
import 'package:marshrutka/core/models/track_point.dart';
import 'package:marshrutka/core/utils/geo_utils.dart';
import 'package:marshrutka/data/local_mock_repository.dart';
import 'package:marshrutka/data/route_loader.dart';

void main() {
  group('RouteLoader', () {
    test('loads and parses route 653 JSON correctly', () async {
      const sampleJson = '''
      [
        {
          "id": "653",
          "name": "653 Волгоград - Реконструкция",
          "TODO_VERIFY": true,
          "stops": [
            { "name": "Центральный автовокзал Волгограда", "lat": 48.7126, "lng": 44.5126, "TODO_VERIFY": true },
            { "name": "п. Реконструкция (конечная)", "lat": 50.3520, "lng": 44.1680, "TODO_VERIFY": true }
          ],
          "polyline": [
            { "lat": 48.7126, "lng": 44.5126, "TODO_VERIFY": true },
            { "lat": 50.3520, "lng": 44.1680, "TODO_VERIFY": true }
          ]
        }
      ]
      ''';

      final loader = RouteLoader();
      final routes = await loader.loadRoutes(sampleJson);

      expect(routes.length, 1);
      final r = routes.first;
      expect(r.id, '653');
      expect(r.name, contains('653 Волгоград - Реконструкция'));
      expect(r.stops.length, 2);
      expect(r.polyline.length, 2);
      expect(r.stops.first.name, contains('Центральный автовокзал'));
      expect(r.stops.first.lat, 48.7126);
    });
  });

  group('LocalMockRepository', () {
    test('isMock is true and emits moving simulated vehicle', () async {
      final repo = LocalMockRepository(
        enableSimulation: true,
        customPolyline: const [
          LatLng(48.7126, 44.5126),
          LatLng(50.3520, 44.1680),
        ],
      );

      expect(repo.isMock, isTrue);

      final firstPoints = await repo.watchActivePoints(AppConstants.defaultRouteId).first;
      expect(firstPoints.isNotEmpty, isTrue);
      expect(firstPoints.first.deviceId, 'simulated-driver-653');
      expect(firstPoints.first.source, 'driver');
      expect(firstPoints.first.routeId, AppConstants.defaultRouteId);

      // Test sending a passenger track point
      final passengerPoint = TrackPoint(
        deviceId: 'user-reporter-1',
        routeId: AppConstants.defaultRouteId,
        lat: 48.72,
        lng: 44.52,
        speed: 10.0,
        accuracy: 5.0,
        source: 'passenger',
        ts: DateTime.now().toUtc(),
      );

      await repo.sendTrackPoint(passengerPoint);
      final updatedPoints = await repo.watchActivePoints(AppConstants.defaultRouteId).first;
      expect(updatedPoints.any((p) => p.deviceId == 'user-reporter-1'), isTrue);

      repo.dispose();
    });
  });

  group('GeoUtils stale and expiry rules', () {
    test('marks points older than 90 seconds as stale', () {
      final now = DateTime.utc(2026, 10, 29, 12, 0, 0);

      final freshPoint = TrackPoint(
        deviceId: 'd1',
        routeId: '653',
        lat: 48.0,
        lng: 44.0,
        speed: 0,
        accuracy: 5,
        source: 'driver',
        ts: DateTime.utc(2026, 10, 29, 11, 59, 0), // 60s ago
      );

      final stalePoint = TrackPoint(
        deviceId: 'd2',
        routeId: '653',
        lat: 48.0,
        lng: 44.0,
        speed: 0,
        accuracy: 5,
        source: 'driver',
        ts: DateTime.utc(2026, 10, 29, 11, 58, 20), // 100s ago
      );

      expect(GeoUtils.isPointStale(freshPoint, now), isFalse);
      expect(GeoUtils.isPointStale(stalePoint, now), isTrue);
    });

    test('marks points older than 10 minutes as expired', () {
      final now = DateTime.utc(2026, 10, 29, 12, 0, 0);

      final validPoint = TrackPoint(
        deviceId: 'd1',
        routeId: '653',
        lat: 48.0,
        lng: 44.0,
        speed: 0,
        accuracy: 5,
        source: 'driver',
        ts: DateTime.utc(2026, 10, 29, 11, 51, 0), // 9 min ago
      );

      final expiredPoint = TrackPoint(
        deviceId: 'd2',
        routeId: '653',
        lat: 48.0,
        lng: 44.0,
        speed: 0,
        accuracy: 5,
        source: 'driver',
        ts: DateTime.utc(2026, 10, 29, 11, 49, 0), // 11 min ago
      );

      expect(GeoUtils.isPointExpired(validPoint, now), isFalse);
      expect(GeoUtils.isPointExpired(expiredPoint, now), isTrue);
    });
  });
}
