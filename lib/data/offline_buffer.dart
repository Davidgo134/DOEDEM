import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import '../core/models/track_point.dart';

/// Append-only local file/JSON offline buffer for storing trackpoints when
/// driving through dead zones on the intercity route (Decision 8).
class OfflineBuffer {
  final File? customFile;
  final int maxPoints;
  List<TrackPoint> _memoryPoints = [];
  bool _isLoaded = false;

  OfflineBuffer({
    this.customFile,
    this.maxPoints = AppConstants.maxOfflineBufferPoints,
  });

  Future<File> _getFile() async {
    if (customFile != null) return customFile!;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.offlineBufferFileName}');
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
          _memoryPoints = jsonList
              .map((item) => TrackPoint.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error reading offline buffer file: $e');
      _memoryPoints = [];
    }
    _isLoaded = true;
  }

  /// Appends a point to the buffer while preserving the original device timestamp (UTC).
  /// Caps the buffer at [maxPoints] (max 2000 points), discarding the oldest if exceeded.
  Future<void> addPoint(TrackPoint point) async {
    await _ensureLoaded();

    _memoryPoints.add(point);
    if (_memoryPoints.length > maxPoints) {
      _memoryPoints = _memoryPoints.sublist(_memoryPoints.length - maxPoints);
    }

    await _saveToFile();
  }

  /// Adds a list of points.
  Future<void> addPoints(List<TrackPoint> points) async {
    await _ensureLoaded();

    _memoryPoints.addAll(points);
    if (_memoryPoints.length > maxPoints) {
      _memoryPoints = _memoryPoints.sublist(_memoryPoints.length - maxPoints);
    }

    await _saveToFile();
  }

  /// Returns all buffered points sorted in strict chronological order.
  Future<List<TrackPoint>> getChronologicalPoints() async {
    await _ensureLoaded();
    final sorted = List<TrackPoint>.from(_memoryPoints);
    sorted.sort((a, b) => a.ts.compareTo(b.ts));
    return sorted;
  }

  /// Flushes (removes) points from the buffer after successful network transmission.
  Future<void> removePoints(List<TrackPoint> pointsToRemove) async {
    await _ensureLoaded();
    final removeSet = pointsToRemove.toSet();
    _memoryPoints.removeWhere((p) => removeSet.contains(p));
    await _saveToFile();
  }

  /// Clears the entire buffer.
  Future<void> clear() async {
    _memoryPoints.clear();
    _isLoaded = true;
    await _saveToFile();
  }

  /// Count of buffered points.
  Future<int> count() async {
    await _ensureLoaded();
    return _memoryPoints.length;
  }

  Future<void> _saveToFile() async {
    try {
      final file = await _getFile();
      final jsonList = _memoryPoints.map((p) => p.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      debugPrint('Error writing offline buffer to disk: $e');
    }
  }
}
