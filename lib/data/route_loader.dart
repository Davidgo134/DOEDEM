import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/models/route_data.dart';
import '../services/osrm_routing_service.dart';

final routeLoaderProvider = Provider<RouteLoader>((ref) => RouteLoader());

final routesFutureProvider = FutureProvider<List<RouteData>>((ref) async {
  final loader = ref.watch(routeLoaderProvider);
  return loader.loadRoutes();
});

class SelectedRouteIdNotifier extends Notifier<String> {
  @override
  String build() => AppConstants.defaultRouteId;

  void selectRoute(String id) {
    state = id;
  }
}

final selectedRouteIdProvider =
    NotifierProvider<SelectedRouteIdNotifier, String>(SelectedRouteIdNotifier.new);

final selectedRouteProvider = FutureProvider<RouteData?>((ref) async {
  final selectedId = ref.watch(selectedRouteIdProvider);
  final routes = await ref.watch(routesFutureProvider.future);
  if (routes.isEmpty) return null;
  final route = routes.firstWhere(
    (r) => r.id == selectedId,
    orElse: () => routes.first,
  );

  // If polyline is missing or empty, dynamically compute it using OSRM
  if (route.polyline.isEmpty && route.stops.length >= 2) {
    try {
      final generatedPolyline = await OsrmRoutingService.fetchRoadGeometry(
        route.stops,
        cacheKey: route.id,
      );
      if (generatedPolyline.isNotEmpty) {
        return route.copyWith(polyline: generatedPolyline);
      }
    } catch (_) {
      // Fallback to existing route
    }
  }

  return route;
});

final defaultRouteFutureProvider = FutureProvider<RouteData?>((ref) async {
  return ref.watch(selectedRouteProvider.future);
});

class RouteLoader {
  static const String assetPath = 'assets/routes.json';

  Future<List<RouteData>> loadRoutes([String? jsonString]) async {
    final raw = jsonString ?? await rootBundle.loadString(assetPath);
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) => RouteData.fromJson(item as Map<String, dynamic>)).toList();
  }
}
