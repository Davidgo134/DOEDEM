import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/models/track_point.dart';

/// Appends every recorded trackpoint to a local CSV file for research and analysis
/// (plan vs actual timing along route 653). (Decision 10)
class CsvLogger {
  final File? customFile;

  CsvLogger({this.customFile});

  Future<File> _getFile() async {
    if (customFile != null) return customFile!;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${AppConstants.trackpointCsvFileName}');
  }

  /// Appends a single trackpoint row to the CSV file.
  /// If the file is newly created, writes the header first.
  Future<void> logPoint(TrackPoint point) async {
    try {
      final file = await _getFile();
      final exists = await file.exists();

      final sink = file.openWrite(mode: FileMode.append);
      if (!exists || (await file.length()) == 0) {
        sink.writeln(TrackPoint.csvHeader());
      }
      sink.writeln(point.toCsvLine());
      await sink.flush();
      await sink.close();
    } catch (e) {
      debugPrint('Error appending to CSV log: $e');
    }
  }

  /// Returns the number of recorded trackpoint rows in the CSV (excluding header).
  Future<int> count() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return 0;
      final lines = await file.readAsLines();
      if (lines.isEmpty) return 0;
      return lines.length - 1; // subtract header
    } catch (e) {
      debugPrint('Error counting CSV log lines: $e');
      return 0;
    }
  }

  /// Shares the CSV log file via the system share sheet using share_plus.
  Future<bool> exportLog() async {
    try {
      final file = await _getFile();
      if (!await file.exists() || (await file.length()) == 0) {
        return false;
      }

      // ignore: deprecated_member_use
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: 'marshrutka_653_log.csv')],
        text: 'Лог трекпоинтов маршрутки №653 (Волгоград - Реконструкция)',
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Error sharing CSV log: $e');
      return false;
    }
  }

  /// Clears the log file.
  Future<void> clear() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing CSV log: $e');
    }
  }
}
