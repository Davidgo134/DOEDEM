import 'package:flutter_test/flutter_test.dart';
import 'package:marshrutka/core/models/track_point.dart';
import 'package:marshrutka/data/websocket_tracking_repository.dart';

void main() {
  group('WebSocketTrackingRepository URL normalization', () {
    test('normalizes https URL to wss with /ws path', () {
      final normalized = WebSocketTrackingRepository.normalizeWsUrl('https://doedem-server.onrender.com');
      expect(normalized, 'wss://doedem-server.onrender.com/ws');
    });

    test('preserves /ws if already present in wss URL', () {
      final normalized = WebSocketTrackingRepository.normalizeWsUrl('wss://doedem-server.onrender.com/ws');
      expect(normalized, 'wss://doedem-server.onrender.com/ws');
    });

    test('normalizes http URL to ws', () {
      final normalized = WebSocketTrackingRepository.normalizeWsUrl('http://192.168.1.50:8080');
      expect(normalized, 'ws://192.168.1.50:8080/ws');
    });

    test('prepends wss if no scheme provided', () {
      final normalized = WebSocketTrackingRepository.normalizeWsUrl('my-server.onrender.com');
      expect(normalized, 'wss://my-server.onrender.com/ws');
    });

    test('returns default when empty string provided', () {
      final normalized = WebSocketTrackingRepository.normalizeWsUrl('   ');
      expect(normalized, 'wss://doedem-transit-server.onrender.com/ws');
    });
  });

  group('WebSocketTrackingRepository offline safeguards', () {
    test('throws SocketException when sending points while disconnected', () async {
      final repo = WebSocketTrackingRepository(serverUrl: 'wss://fake-inactive-domain-123.com/ws');

      final point = TrackPoint(
        deviceId: 'dev-1',
        routeId: '174',
        lat: 48.71,
        lng: 44.51,
        speed: 10,
        accuracy: 5,
        source: 'driver',
        ts: DateTime.now().toUtc(),
      );

      expect(() => repo.sendTrackPoint(point), throwsA(isA<Exception>()));
      expect(() => repo.sendBufferedPoints([point]), throwsA(isA<Exception>()));

      repo.dispose();
    });
  });
}
