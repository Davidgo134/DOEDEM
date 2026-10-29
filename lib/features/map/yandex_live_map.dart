import 'dart:math';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart' as yandex;

import '../../core/models/route_data.dart';
import '../../core/models/track_point.dart';
import '../../core/utils/geo_utils.dart';
import 'live_map_view.dart';

class YandexLiveMapController implements LiveMapController {
  final yandex.YandexMapController _controller;

  YandexLiveMapController(this._controller);

  @override
  void centerOnPoint(double lat, double lng, {double zoom = 12.0}) {
    _controller.moveCamera(
      yandex.CameraUpdate.newCameraPosition(
        yandex.CameraPosition(
          target: yandex.Point(latitude: lat, longitude: lng),
          zoom: zoom,
        ),
      ),
      animation: const yandex.MapAnimation(
        type: yandex.MapAnimationType.smooth,
        duration: 0.8,
      ),
    );
  }

  @override
  void centerOnRoute(RouteData route) {
    if (route.polyline.isEmpty) return;
    double minLat = route.polyline.first.lat;
    double maxLat = route.polyline.first.lat;
    double minLng = route.polyline.first.lng;
    double maxLng = route.polyline.first.lng;

    for (final p in route.polyline) {
      minLat = min(minLat, p.lat);
      maxLat = max(maxLat, p.lat);
      minLng = min(minLng, p.lng);
      maxLng = max(maxLng, p.lng);
    }

    _controller.moveCamera(
      yandex.CameraUpdate.newGeometry(
        yandex.Geometry.fromBoundingBox(
          yandex.BoundingBox(
            southWest: yandex.Point(latitude: minLat, longitude: minLng),
            northEast: yandex.Point(latitude: maxLat, longitude: maxLng),
          ),
        ),
      ),
      animation: const yandex.MapAnimation(
        type: yandex.MapAnimationType.smooth,
        duration: 1.0,
      ),
    );
  }
}

class YandexLiveMap extends StatefulWidget {
  final RouteData? route;
  final List<TrackPoint> activePoints;
  final TrackPoint? selectedPoint;
  final VehicleTapCallback? onVehicleTap;
  final void Function(LiveMapController controller)? onMapCreated;

  const YandexLiveMap({
    super.key,
    required this.route,
    required this.activePoints,
    this.selectedPoint,
    this.onVehicleTap,
    this.onMapCreated,
  });

  @override
  State<YandexLiveMap> createState() => _YandexLiveMapState();
}

class _YandexLiveMapState extends State<YandexLiveMap> {
  YandexLiveMapController? _mapController;

  static const yandex.Point _volgogradCenter = yandex.Point(
    latitude: 49.53,
    longitude: 44.34,
  );

  List<yandex.MapObject> _buildMapObjects() {
    final objects = <yandex.MapObject>[];

    // Route polyline
    if (widget.route != null && widget.route!.polyline.isNotEmpty) {
      objects.add(
        yandex.PolylineMapObject(
          mapId: const yandex.MapObjectId('route_polyline_653'),
          polyline: yandex.Polyline(
            points: widget.route!.polyline
                .map((c) => yandex.Point(latitude: c.lat, longitude: c.lng))
                .toList(),
          ),
          strokeColor: const Color(0xFF006C50),
          strokeWidth: 4.5,
        ),
      );

      // Route stops
      for (int i = 0; i < widget.route!.stops.length; i++) {
        final stop = widget.route!.stops[i];
        objects.add(
          yandex.CircleMapObject(
            mapId: yandex.MapObjectId('stop_$i'),
            circle: yandex.Circle(
              center: yandex.Point(latitude: stop.lat, longitude: stop.lng),
              radius: 60.0,
            ),
            fillColor: Colors.white,
            strokeColor: const Color(0xFF006C50),
            strokeWidth: 3.0,
          ),
        );
      }
    }

    // Active vehicles
    for (final point in widget.activePoints) {
      final isStale = GeoUtils.isPointStale(point);
      final isSelected = widget.selectedPoint == point;
      final color = isStale
          ? Colors.grey
          : (point.isDriver ? const Color(0xFF006C50) : Colors.teal);

      objects.add(
        yandex.CircleMapObject(
          mapId: yandex.MapObjectId('vehicle_${point.deviceId}'),
          circle: yandex.Circle(
            center: yandex.Point(latitude: point.lat, longitude: point.lng),
            radius: isSelected ? 120.0 : 80.0,
          ),
          fillColor: color.withValues(alpha: 0.85),
          strokeColor: Colors.white,
          strokeWidth: isSelected ? 4.0 : 2.5,
          onTap: (mapObject, targetPoint) {
            widget.onVehicleTap?.call(point);
          },
        ),
      );
    }

    return objects;
  }

  @override
  Widget build(BuildContext context) {
    return yandex.YandexMap(
      onMapCreated: (controller) {
        _mapController = YandexLiveMapController(controller);
        widget.onMapCreated?.call(_mapController!);

        // Move to initial center
        _mapController!.centerOnPoint(
          _volgogradCenter.latitude,
          _volgogradCenter.longitude,
          zoom: 7.5,
        );
      },
      mapObjects: _buildMapObjects(),
    );
  }
}
