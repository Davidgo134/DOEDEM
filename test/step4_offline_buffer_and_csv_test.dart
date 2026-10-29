import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:marshrutka/core/models/track_point.dart';
import 'package:marshrutka/data/csv_logger.dart';
import 'package:marshrutka/data/offline_buffer.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('marshrutka_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('OfflineBuffer', () {
    test('preserves device timestamp and flushes in strict chronological order', () async {
      final bufferFile = File('${tempDir.path}/test_buffer.json');
      final buffer = OfflineBuffer(customFile: bufferFile);

      final t1 = DateTime.utc(2026, 10, 29, 12, 0, 10);
      final t2 = DateTime.utc(2026, 10, 29, 12, 0, 20);
      final t3 = DateTime.utc(2026, 10, 29, 12, 0, 30);

      final p1 = TrackPoint(
        deviceId: 'd1',
        routeId: '653',
        lat: 48.1,
        lng: 44.1,
        speed: 10,
        accuracy: 5,
        source: 'driver',
        ts: t1,
      );

      final p2 = TrackPoint(
        deviceId: 'd1',
        routeId: '653',
        lat: 48.2,
        lng: 44.2,
        speed: 12,
        accuracy: 4,
        source: 'driver',
        ts: t2,
      );

      final p3 = TrackPoint(
        deviceId: 'd1',
        routeId: '653',
        lat: 48.3,
        lng: 44.3,
        speed: 15,
        accuracy: 3,
        source: 'driver',
        ts: t3,
      );

      // Add points out of order to verify sorting
      await buffer.addPoint(p2);
      await buffer.addPoint(p1);
      await buffer.addPoint(p3);

      expect(await buffer.count(), 3);

      final chronological = await buffer.getChronologicalPoints();
      expect(chronological.length, 3);
      expect(chronological[0].ts, t1); // Oldest first
      expect(chronological[1].ts, t2);
      expect(chronological[2].ts, t3);

      // Verify device timestamp was strictly preserved
      expect(chronological[0].lat, 48.1);
      expect(chronological[2].lat, 48.3);

      // Verify removing flushed points
      await buffer.removePoints([p1, p2]);
      expect(await buffer.count(), 1);
      final remaining = await buffer.getChronologicalPoints();
      expect(remaining.first, p3);
    });

    test('caps buffer size at maxPoints discarding oldest', () async {
      final bufferFile = File('${tempDir.path}/test_buffer_cap.json');
      final buffer = OfflineBuffer(customFile: bufferFile, maxPoints: 3);

      for (int i = 1; i <= 5; i++) {
        await buffer.addPoint(
          TrackPoint(
            deviceId: 'd1',
            routeId: '653',
            lat: 48.0 + i,
            lng: 44.0 + i,
            speed: 10,
            accuracy: 5,
            source: 'driver',
            ts: DateTime.utc(2026, 10, 29, 12, i, 0),
          ),
        );
      }

      expect(await buffer.count(), 3);
      final points = await buffer.getChronologicalPoints();
      expect(points.first.lat, 51.0); // Point 3
      expect(points.last.lat, 53.0);  // Point 5
    });
  });

  group('CsvLogger', () {
    test('logs points to CSV with correct header and format', () async {
      final csvFile = File('${tempDir.path}/test_log.csv');
      final logger = CsvLogger(customFile: csvFile);

      expect(await logger.count(), 0);

      final point1 = TrackPoint(
        deviceId: 'device-test-1',
        routeId: '653',
        lat: 48.7126,
        lng: 44.5126,
        speed: 18.5,
        accuracy: 5.2,
        source: 'driver',
        ts: DateTime.utc(2026, 10, 29, 12, 0, 0),
      );

      final point2 = TrackPoint(
        deviceId: 'device-test-2',
        routeId: '653',
        lat: 50.3520,
        lng: 44.1680,
        speed: 0.0,
        accuracy: 3.1,
        source: 'passenger',
        ts: DateTime.utc(2026, 10, 29, 12, 1, 0),
      );

      await logger.logPoint(point1);
      await logger.logPoint(point2);

      expect(await logger.count(), 2);

      final lines = await csvFile.readAsLines();
      expect(lines.length, 3);
      expect(lines[0], TrackPoint.csvHeader());
      expect(lines[1], point1.toCsvLine());
      expect(lines[2], point2.toCsvLine());

      // Parse back from CSV
      final parsed1 = TrackPoint.fromCsvLine(lines[1]);
      expect(parsed1, point1);
      final parsed2 = TrackPoint.fromCsvLine(lines[2]);
      expect(parsed2, point2);
    });
  });
}
