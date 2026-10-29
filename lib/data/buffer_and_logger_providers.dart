import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'csv_logger.dart';
import 'offline_buffer.dart';

final offlineBufferProvider = Provider<OfflineBuffer>((ref) => OfflineBuffer());
final csvLoggerProvider = Provider<CsvLogger>((ref) => CsvLogger());
