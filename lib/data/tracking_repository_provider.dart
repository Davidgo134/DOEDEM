import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/track_point.dart';
import 'firestore_repository.dart';
import 'local_mock_repository.dart';
import 'tracking_repository.dart';

/// Provider holding the active tracking repository.
/// Automatically detects if Firebase is configured/initialized.
/// If google-services.json is absent, silently falls back to LocalMockRepository (isMock = true).
final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  // Check if Firebase is initialized
  final bool hasFirebase = Firebase.apps.isNotEmpty;

  TrackingRepository repo;
  if (hasFirebase) {
    try {
      repo = FirestoreRepository();
      debugPrint('TrackingRepository: using FirestoreRepository');
    } catch (e) {
      debugPrint('Firestore initialization failed ($e), falling back to LocalMockRepository');
      repo = LocalMockRepository();
    }
  } else {
    debugPrint('TrackingRepository: Firebase not initialized, using LocalMockRepository (Demo-mode)');
    repo = LocalMockRepository();
  }

  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

final activeRoutePointsStreamProvider = StreamProvider.family<List<TrackPoint>, String>((ref, routeId) {
  final repo = ref.watch(trackingRepositoryProvider);
  return repo.watchActivePoints(routeId);
});
