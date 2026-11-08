import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/models/track_point.dart';
import 'tracking_repository.dart';

enum WsConnectionStatus {
  disconnected,
  connecting,
  connected,
}

/// WebSocket real-time tracking repository for DOEDEM.
/// Connects to the standalone Render.com WebSocket server.
/// Supports auto-reconnect, keep-alive heartbeat, route subscriptions,
/// and bidirectional GPS point streaming.
class WebSocketTrackingRepository implements TrackingRepository {
  String serverUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  final ValueNotifier<WsConnectionStatus> connectionStatus =
      ValueNotifier<WsConnectionStatus>(WsConnectionStatus.disconnected);

  final Set<String> _subscribedRoutes = <String>{};
  final Map<String, StreamController<List<TrackPoint>>> _routeControllers = {};
  final Map<String, List<TrackPoint>> _routeCache = {};

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectDelaySeconds = 2;
  bool _isDisposed = false;

  WebSocketTrackingRepository({required this.serverUrl}) {
    _connect();
  }

  @override
  bool get isMock => false;

  String get currentUrl => serverUrl;

  /// Update server URL and trigger immediate reconnect (e.g. from Settings).
  void updateUrl(String newUrl) {
    if (serverUrl == newUrl) return;
    serverUrl = newUrl;
    _reconnectDelaySeconds = 2;
    _disconnect();
    _connect();
  }

  /// Normalize URL to ensure ws:// or wss:// scheme and /ws path.
  static String normalizeWsUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (url.isEmpty) return 'wss://doedem-transit-server.onrender.com/ws';

    if (url.startsWith('https://')) {
      url = 'wss://${url.substring(8)}';
    } else if (url.startsWith('http://')) {
      url = 'ws://${url.substring(7)}';
    } else if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      url = 'wss://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri != null && (uri.path.isEmpty || uri.path == '/')) {
      url = '$url/ws';
    }
    return url;
  }

  void _connect() {
    if (_isDisposed) return;
    _cancelReconnectTimer();

    final normalized = normalizeWsUrl(serverUrl);
    debugPrint('WebSocketTrackingRepository: connecting to $normalized');
    connectionStatus.value = WsConnectionStatus.connecting;

    try {
      final uri = Uri.parse(normalized);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      _channelSubscription = channel.stream.listen(
        _onMessageReceived,
        onDone: _onDisconnected,
        onError: _onError,
        cancelOnError: true,
      );

      channel.ready.then((_) {
        if (_isDisposed || _channel != channel) return;
        connectionStatus.value = WsConnectionStatus.connected;
        _reconnectDelaySeconds = 2;
        _startPingTimer();

        // Re-subscribe to all active routes upon connection
        for (final routeId in _subscribedRoutes) {
          _sendSubscribe(routeId);
        }
      }).catchError((err) {
        if (_isDisposed || _channel != channel) return;
        debugPrint('WebSocketTrackingRepository: channel ready error: $err');
        _onDisconnected();
      });
    } catch (e) {
      debugPrint('WebSocketTrackingRepository: connection error: $e');
      _onDisconnected();
    }
  }

  void _disconnect() {
    _stopPingTimer();
    _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    connectionStatus.value = WsConnectionStatus.disconnected;
  }

  void _onDisconnected() {
    if (_isDisposed) return;
    debugPrint('WebSocketTrackingRepository: connection closed');
    _disconnect();
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    if (_isDisposed) return;
    debugPrint('WebSocketTrackingRepository: socket error: $error');
    _disconnect();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed || _reconnectTimer?.isActive == true) return;

    debugPrint('WebSocketTrackingRepository: reconnecting in $_reconnectDelaySeconds seconds...');
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySeconds), () {
      _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(2, 20);
      _connect();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _sendRaw({'type': 'ping'});
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _sendRaw(Map<String, dynamic> data) {
    if (_channel == null || connectionStatus.value != WsConnectionStatus.connected) {
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('WebSocketTrackingRepository: send error: $e');
    }
  }

  void _sendSubscribe(String routeId) {
    _sendRaw({'type': 'subscribe', 'routeId': routeId});
  }

  void _sendUnsubscribe(String routeId) {
    _sendRaw({'type': 'unsubscribe', 'routeId': routeId});
  }

  void _onMessageReceived(dynamic message) {
    try {
      final raw = message.toString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'init' || type == 'update') {
        final routeId = data['routeId'] as String?;
        final rawPoints = data['points'] as List<dynamic>? ?? [];

        if (routeId != null) {
          final points = rawPoints
              .map((p) => TrackPoint.fromJson(p as Map<String, dynamic>))
              .toList();

          _routeCache[routeId] = points;
          final controller = _routeControllers[routeId];
          if (controller != null && !controller.isClosed) {
            controller.add(points);
          }
        }
      }
    } catch (e) {
      debugPrint('WebSocketTrackingRepository: message parse error: $e');
    }
  }

  StreamController<List<TrackPoint>> _getOrCreateController(String routeId) {
    if (!_routeControllers.containsKey(routeId)) {
      _routeControllers[routeId] = StreamController<List<TrackPoint>>.broadcast(
        onListen: () {
          _subscribedRoutes.add(routeId);
          _sendSubscribe(routeId);
          // Emit initial cached data if present
          final cached = _routeCache[routeId];
          if (cached != null) {
            _routeControllers[routeId]?.add(cached);
          }
        },
        onCancel: () {
          _subscribedRoutes.remove(routeId);
          _sendUnsubscribe(routeId);
        },
      );
    }
    return _routeControllers[routeId]!;
  }

  @override
  Stream<List<TrackPoint>> watchActivePoints(String routeId) {
    final controller = _getOrCreateController(routeId);
    return controller.stream;
  }

  @override
  Future<void> sendTrackPoint(TrackPoint point) async {
    if (connectionStatus.value != WsConnectionStatus.connected || _channel == null) {
      throw const SocketException('WebSocket server is not connected');
    }

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'track_point',
        'point': point.toJson(),
      }));
    } catch (e) {
      throw SocketException('Failed to deliver trackpoint: $e');
    }
  }

  @override
  Future<void> sendBufferedPoints(List<TrackPoint> points) async {
    if (points.isEmpty) return;
    if (connectionStatus.value != WsConnectionStatus.connected || _channel == null) {
      throw const SocketException('WebSocket server is not connected');
    }

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'track_batch',
        'points': points.map((p) => p.toJson()).toList(),
      }));
    } catch (e) {
      throw SocketException('Failed to deliver buffered trackpoints: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelReconnectTimer();
    _stopPingTimer();
    _disconnect();
    connectionStatus.dispose();
    for (final controller in _routeControllers.values) {
      controller.close();
    }
    _routeControllers.clear();
    _routeCache.clear();
  }
}
