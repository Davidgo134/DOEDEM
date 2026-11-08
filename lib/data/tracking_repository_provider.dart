import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/track_point.dart';
import '../core/utils/preferences_service.dart';
import 'local_mock_repository.dart';
import 'tracking_repository.dart';
import 'websocket_tracking_repository.dart';

/// Active WebSocket tracking repository provider.
final webSocketTrackingRepositoryProvider = Provider<WebSocketTrackingRepository?>((ref) {
  final isTest = Platform.environment.containsKey('FLUTTER_TEST');
  if (isTest) return null;

  final prefs = ref.watch(preferencesServiceProvider);
  final url = prefs.getWebSocketUrl();
  final repo = WebSocketTrackingRepository(serverUrl: url);

  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

/// Main tracking repository provider used throughout the application.
/// Defaults to the real WebSocket backend on Render.com.
/// Falls back to LocalMockRepository in automated test environments.
final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final isTest = Platform.environment.containsKey('FLUTTER_TEST');
  if (isTest) {
    final mock = LocalMockRepository();
    ref.onDispose(() => mock.dispose());
    return mock;
  }

  final wsRepo = ref.watch(webSocketTrackingRepositoryProvider);
  if (wsRepo != null) {
    return wsRepo;
  }

  final mock = LocalMockRepository();
  ref.onDispose(() => mock.dispose());
  return mock;
});

/// Stream of real-time active points for a specific route.
final activeRoutePointsStreamProvider = StreamProvider.family<List<TrackPoint>, String>((ref, routeId) {
  final repo = ref.watch(trackingRepositoryProvider);
  return repo.watchActivePoints(routeId);
});

/// Stream of WebSocket connection status for live UI indicators.
final wsConnectionStatusStreamProvider = StreamProvider<WsConnectionStatus>((ref) {
  final wsRepo = ref.watch(webSocketTrackingRepositoryProvider);
  if (wsRepo == null) {
    return Stream.value(WsConnectionStatus.disconnected);
  }

  final controller = StreamController<WsConnectionStatus>();
  controller.add(wsRepo.connectionStatus.value);

  void listener() {
    if (!controller.isClosed) {
      controller.add(wsRepo.connectionStatus.value);
    }
  }

  wsRepo.connectionStatus.addListener(listener);

  ref.onDispose(() {
    wsRepo.connectionStatus.removeListener(listener);
    controller.close();
  });

  return controller.stream;
});
