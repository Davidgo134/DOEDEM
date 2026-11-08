import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/route_data.dart';

/// OSRM Routing Service for on-the-fly road geometry generation.
/// Works globally for any city without requiring proprietary paid APIs.
class OsrmRoutingService {
  static const String _osrmHost = 'router.project-osrm.org';
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  // In-memory cache for generated polylines
  static final Map<String, List<RouteCoord>> _cache = {};

  /// Computes high-precision road geometry between a list of stops.
  static Future<List<RouteCoord>> fetchRoadGeometry(
    List<RouteStop> stops, {
    String? cacheKey,
  }) async {
    if (stops.length < 2) return [];

    if (cacheKey != null && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final List<RouteCoord> fullPolyline = [];

    // Query in segments of up to 4 consecutive waypoints to balance request size and speed
    for (int i = 0; i < stops.length - 1; i++) {
      final s1 = stops[i];
      final s2 = stops[i + 1];

      try {
        final uri = Uri.http(
          _osrmHost,
          '/route/v1/driving/${s1.lng},${s1.lat};${s2.lng},${s2.lat}',
          {
            'overview': 'full',
            'geometries': 'geojson',
          },
        );

        final request = await _httpClient.getUrl(uri);
        request.headers.set('User-Agent', 'DOEDEM-Transport/1.0');
        final response = await request.close();

        if (response.statusCode == 200) {
          final bodyString = await response.transform(utf8.decoder).join();
          final data = json.decode(bodyString) as Map<String, dynamic>;
          final routes = data['routes'] as List<dynamic>?;

          if (routes != null && routes.isNotEmpty) {
            final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
            final coordinates = geometry?['coordinates'] as List<dynamic>?;

            if (coordinates != null) {
              for (final coord in coordinates) {
                final lng = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                fullPolyline.add(RouteCoord(lat: lat, lng: lng));
              }
            }
          }
        } else {
          fullPolyline.add(RouteCoord(lat: s1.lat, lng: s1.lng));
          fullPolyline.add(RouteCoord(lat: s2.lat, lng: s2.lng));
        }
      } catch (e) {
        debugPrint('OSRM routing segment error ($s1 -> $s2): $e');
        fullPolyline.add(RouteCoord(lat: s1.lat, lng: s1.lng));
        fullPolyline.add(RouteCoord(lat: s2.lat, lng: s2.lng));
      }
    }

    // Deduplicate consecutive identical points
    final List<RouteCoord> deduped = [];
    for (final pt in fullPolyline) {
      if (deduped.isEmpty ||
          deduped.last.lat != pt.lat ||
          deduped.last.lng != pt.lng) {
        deduped.add(pt);
      }
    }

    if (cacheKey != null && deduped.isNotEmpty) {
      _cache[cacheKey] = deduped;
    }

    return deduped;
  }
}
