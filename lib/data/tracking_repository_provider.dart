import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/track_point.dart';
import 'local_mock_repository.dart';
import 'tracking_repository.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final repo = LocalMockRepository();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

final activeRoutePointsStreamProvider = StreamProvider.family<List<TrackPoint>, String>((ref, routeId) {
  final repo = ref.watch(trackingRepositoryProvider);
  return repo.watchActivePoints(routeId);
});
