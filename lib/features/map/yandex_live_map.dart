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
  final RouteStop? selectedStop;
  final VehicleTapCallback? onVehicleTap;
  final StopTapCallback? onStopTap;
  final void Function(LiveMapController controller)? onMapCreated;

  const YandexLiveMap({
    super.key,
    required this.route,
    required this.activePoints,
    this.selectedPoint,
    this.selectedStop,
    this.onVehicleTap,
    this.onStopTap,
    this.onMapCreated,
  });

  @override
  State<YandexLiveMap> createState() => _YandexLiveMapState();
}

class _YandexLiveMapState extends State<YandexLiveMap> {
  YandexLiveMapController? _mapController;

  static const yandex.Point _volgogradCenter = yandex.Point(
    latitude: 48.7126,
    longitude: 44.5126,
  );

  Color _parseRouteColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF006C50);
    try {
      final buffer = StringBuffer();
      if (hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF006C50);
    }
  }

  List<yandex.MapObject> _buildMapObjects() {
    final objects = <yandex.MapObject>[];
    final routeColor = _parseRouteColor(widget.route?.color);

    // Route polyline
    if (widget.route != null && widget.route!.polyline.isNotEmpty) {
      objects.add(
        yandex.PolylineMapObject(
          mapId: yandex.MapObjectId('route_polyline_${widget.route!.id}'),
          polyline: yandex.Polyline(
            points: widget.route!.polyline
                .map((c) => yandex.Point(latitude: c.lat, longitude: c.lng))
                .toList(),
          ),
          strokeColor: routeColor,
          strokeWidth: 4.5,
        ),
      );

      // Route stops
      for (int i = 0; i < widget.route!.stops.length; i++) {
        final stop = widget.route!.stops[i];
        final isSelectedStop = widget.selectedStop?.name == stop.name;

        objects.add(
          yandex.CircleMapObject(
            mapId: yandex.MapObjectId('stop_${widget.route!.id}_$i'),
            circle: yandex.Circle(
              center: yandex.Point(latitude: stop.lat, longitude: stop.lng),
              radius: isSelectedStop ? 90.0 : 50.0,
            ),
            fillColor: isSelectedStop ? routeColor : Colors.white,
            strokeColor: routeColor,
            strokeWidth: isSelectedStop ? 4.0 : 2.5,
            onTap: (mapObject, targetPoint) {
              widget.onStopTap?.call(stop);
            },
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
  void didUpdateWidget(covariant YandexLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route != null && widget.route?.id != oldWidget.route?.id && _mapController != null) {
      _mapController!.centerOnRoute(widget.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return yandex.YandexMap(
      onMapCreated: (controller) {
        _mapController = YandexLiveMapController(controller);
        widget.onMapCreated?.call(_mapController!);

        if (widget.route != null) {
          _mapController!.centerOnRoute(widget.route!);
        } else {
          _mapController!.centerOnPoint(
            _volgogradCenter.latitude,
            _volgogradCenter.longitude,
            zoom: 10.0,
          );
        }
      },
      mapObjects: _buildMapObjects(),
    );
  }
}
