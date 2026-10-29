import 'package:flutter_test/flutter_test.dart';
import 'package:marshrutka/core/models/track_point.dart';
import 'package:marshrutka/data/local_mock_repository.dart';
import 'package:marshrutka/services/location_service.dart';
import 'package:marshrutka/services/tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('TrackingState default values', () {
    const state = TrackingState(isTracking: false);
    expect(state.isTracking, isFalse);
    expect(state.activeSource, isNull);
    expect(state.gpsStatus, GpsSignalStatus.searching);
    expect(state.bufferedPointsCount, 0);
    expect(state.lastRecordedPoint, isNull);
  });

  test('TrackingState copyWith preserves and updates values', () {
    const state = TrackingState(isTracking: false);
    final updated = state.copyWith(
      isTracking: true,
      activeSource: 'driver',
      gpsStatus: GpsSignalStatus.ok,
      bufferedPointsCount: 5,
    );

    expect(updated.isTracking, isTrue);
    expect(updated.activeSource, 'driver');
    expect(updated.gpsStatus, GpsSignalStatus.ok);
    expect(updated.bufferedPointsCount, 5);
  });

  test('LocalMockRepository receives driver track point and notifies listeners', () async {
    final repo = LocalMockRepository();

    final testPoint = TrackPoint(
      deviceId: 'test-driver-id',
      routeId: '653',
      lat: 48.7126,
      lng: 44.5126,
      speed: 15.0,
      accuracy: 4.0,
      source: 'driver',
      ts: DateTime.now().toUtc(),
    );

    await repo.sendTrackPoint(testPoint);
    final points = await repo.watchActivePoints('653').first;

    expect(points.any((p) => p.deviceId == 'test-driver-id' && p.source == 'driver'), isTrue);
    repo.dispose();
  });
}
