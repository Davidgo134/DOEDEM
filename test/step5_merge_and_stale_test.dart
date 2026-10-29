import 'package:flutter_test/flutter_test.dart';
import 'package:marshrutka/core/models/track_point.dart';
import 'package:marshrutka/core/utils/merge_logic.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 29, 12, 0, 0);

  group('mergeTrackPoints unit tests (Decision 9 & 6)', () {
    test('deduplicates per deviceId, keeping only the newest point', () {
      final pOld = TrackPoint(
        deviceId: 'device-1',
        routeId: '653',
        lat: 48.7100,
        lng: 44.5100,
        speed: 10,
        accuracy: 5,
        source: 'driver',
        ts: baseTime.subtract(const Duration(seconds: 40)),
      );

      final pNew = TrackPoint(
        deviceId: 'device-1',
        routeId: '653',
        lat: 48.7150,
        lng: 44.5150,
        speed: 12,
        accuracy: 4,
        source: 'driver',
        ts: baseTime,
      );

      final result = mergeTrackPoints([pOld, pNew], now: baseTime);
      expect(result.length, 1);
      expect(result.first.lat, 48.7150);
      expect(result.first.ts, baseTime);
    });

    test('discards points older than 10 minutes (600s)', () {
      final expiredPoint = TrackPoint(
        deviceId: 'device-old',
        routeId: '653',
        lat: 48.7100,
        lng: 44.5100,
        speed: 0,
        accuracy: 5,
        source: 'passenger',
        ts: baseTime.subtract(const Duration(seconds: 601)),
      );

      final activePoint = TrackPoint(
        deviceId: 'device-fresh',
        routeId: '653',
        lat: 48.7100,
        lng: 44.5100,
        speed: 0,
        accuracy: 5,
        source: 'passenger',
        ts: baseTime.subtract(const Duration(seconds: 590)),
      );

      final result = mergeTrackPoints([expiredPoint, activePoint], now: baseTime);
      expect(result.length, 1);
      expect(result.first.deviceId, 'device-fresh');
    });

    test('merges driver and passenger within 150m and within 60s, preferring driver', () {
      // Driver at Central Bus Station Volgograd
      final driver = TrackPoint(
        deviceId: 'driver-1',
        routeId: '653',
        lat: 48.71260,
        lng: 44.51260,
        speed: 15,
        accuracy: 5,
        source: 'driver',
        ts: baseTime,
      );

      // Passenger 50 meters away, timestamp 15s earlier
      // 0.00045 deg lat is approx 50 meters
      final passengerNear = TrackPoint(
        deviceId: 'passenger-1',
        routeId: '653',
        lat: 48.71290,
        lng: 44.51260,
        speed: 15,
        accuracy: 8,
        source: 'passenger',
        ts: baseTime.subtract(const Duration(seconds: 15)),
      );

      final result = mergeTrackPoints([driver, passengerNear], now: baseTime);

      expect(result.length, 1);
      expect(result.first.deviceId, 'driver-1');
      expect(result.first.isDriver, isTrue);
    });

    test('does NOT merge driver and passenger if distance > 150m', () {
      final driver = TrackPoint(
        deviceId: 'driver-1',
        routeId: '653',
        lat: 48.71260,
        lng: 44.51260,
        speed: 15,
        accuracy: 5,
        source: 'driver',
        ts: baseTime,
      );

      // Passenger ~500m away
      // 0.0045 deg lat is approx 500 meters
      final passengerFar = TrackPoint(
        deviceId: 'passenger-far',
        routeId: '653',
        lat: 48.71710,
        lng: 44.51260,
        speed: 15,
        accuracy: 8,
        source: 'passenger',
        ts: baseTime,
      );

      final result = mergeTrackPoints([driver, passengerFar], now: baseTime);

      expect(result.length, 2);
      expect(result.any((p) => p.deviceId == 'driver-1'), isTrue);
      expect(result.any((p) => p.deviceId == 'passenger-far'), isTrue);
    });

    test('does NOT merge driver and passenger if time difference > 60s', () {
      final driver = TrackPoint(
        deviceId: 'driver-1',
        routeId: '653',
        lat: 48.71260,
        lng: 44.51260,
        speed: 0,
        accuracy: 5,
        source: 'driver',
        ts: baseTime,
      );

      // Passenger right next to driver (10m away), but recorded 80s ago
      final passengerOld = TrackPoint(
        deviceId: 'passenger-old',
        routeId: '653',
        lat: 48.71265,
        lng: 44.51260,
        speed: 0,
        accuracy: 5,
        source: 'passenger',
        ts: baseTime.subtract(const Duration(seconds: 80)),
      );

      final result = mergeTrackPoints([driver, passengerOld], now: baseTime);

      expect(result.length, 2);
    });

    test('merges multiple passengers within 150m and within 60s into ONE marker (newest)', () {
      final p1 = TrackPoint(
        deviceId: 'passenger-older',
        routeId: '653',
        lat: 48.71260,
        lng: 44.51260,
        speed: 10,
        accuracy: 6,
        source: 'passenger',
        ts: baseTime.subtract(const Duration(seconds: 25)),
      );

      final p2 = TrackPoint(
        deviceId: 'passenger-newest',
        routeId: '653',
        lat: 48.71280,
        lng: 44.51270, // ~30m away
        speed: 10,
        accuracy: 5,
        source: 'passenger',
        ts: baseTime.subtract(const Duration(seconds: 5)),
      );

      final result = mergeTrackPoints([p1, p2], now: baseTime);

      expect(result.length, 1);
      expect(result.first.deviceId, 'passenger-newest');
    });

    test('does not merge vehicles across different routes', () {
      final pRoute653 = TrackPoint(
        deviceId: 'd1',
        routeId: '653',
        lat: 48.71260,
        lng: 44.51260,
        speed: 0,
        accuracy: 5,
        source: 'driver',
        ts: baseTime,
      );

      final pRouteOther = TrackPoint(
        deviceId: 'd2',
        routeId: '999',
        lat: 48.71260,
        lng: 44.51260,
        speed: 0,
        accuracy: 5,
        source: 'passenger',
        ts: baseTime,
      );

      final result = mergeTrackPoints([pRoute653, pRouteOther], now: baseTime);
      expect(result.length, 2);
    });
  });
}
