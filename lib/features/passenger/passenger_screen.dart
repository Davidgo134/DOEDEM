import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../core/models/route_data.dart';
import '../../core/models/track_point.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/merge_logic.dart';
import '../../data/route_loader.dart';
import '../../data/tracking_repository_provider.dart';
import '../map/live_map.dart';
import '../map/live_map_view.dart';
import '../settings/settings_screen.dart';
import 'route_details_sheet.dart';
import 'route_picker_sheet.dart';

class PassengerScreen extends ConsumerStatefulWidget {
  const PassengerScreen({super.key});

  @override
  ConsumerState<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends ConsumerState<PassengerScreen> {
  LiveMapController? _mapController;
  TrackPoint? _selectedPoint;
  RouteStop? _selectedStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeAsync = ref.watch(selectedRouteProvider);
    final selectedRouteId = ref.watch(selectedRouteIdProvider);
    final trackingRepo = ref.watch(trackingRepositoryProvider);
    final pointsAsync = ref.watch(activeRoutePointsStreamProvider(selectedRouteId));

    final rawPoints = pointsAsync.value ?? [];
    // Apply merge and stale/expiry logic (Decisions 6 & 9)
    final activePoints = mergeTrackPoints(rawPoints);
    final currentRoute = routeAsync.value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => RoutePickerSheet.show(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentRoute != null ? '№ ${currentRoute.id}' : 'Маршрут',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    currentRoute?.name ?? AppStrings.pilotRouteTitle,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
                if (trackingRepo.isMock) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      AppStrings.demoModeBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Выбрать маршрут',
            onPressed: () => RoutePickerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settingsTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live Map Interface (Swappable implementation: Yandex or Fallback)
          LiveMap(
            route: currentRoute,
            activePoints: activePoints,
            selectedPoint: _selectedPoint,
            selectedStop: _selectedStop,
            onVehicleTap: (point) {
              setState(() {
                _selectedPoint = point;
                _selectedStop = null;
              });
            },
            onStopTap: (stop) {
              setState(() {
                _selectedStop = stop;
                _selectedPoint = null;
              });
              _mapController?.centerOnPoint(stop.lat, stop.lng, zoom: 14.5);
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Остановка: ${stop.name}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Selected Vehicle Info Card (if tapped on vehicle)
          if (_selectedPoint != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_bus_rounded,
                        color: _selectedPoint!.isDriver
                            ? theme.colorScheme.primary
                            : Colors.teal.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Маршрутка №${_selectedPoint!.routeId} (${_selectedPoint!.isDriver ? AppStrings.passengerSourceDriver : AppStrings.passengerSourcePassenger})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              GeoUtils.formatPointAge(_selectedPoint!),
                              style: TextStyle(
                                fontSize: 13,
                                color: GeoUtils.isPointStale(_selectedPoint!)
                                    ? Colors.grey.shade700
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedPoint = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Action Buttons (Center route / vehicle)
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center_route',
                  tooltip: AppStrings.passengerCenterRoute,
                  onPressed: () {
                    if (currentRoute != null) {
                      _mapController?.centerOnRoute(currentRoute);
                    }
                  },
                  child: const Icon(Icons.route_outlined),
                ),
                const SizedBox(height: 8),
                if (activePoints.isNotEmpty)
                  FloatingActionButton.small(
                    heroTag: 'center_vehicle',
                    tooltip: AppStrings.passengerCenterVehicle,
                    onPressed: () {
                      final first = activePoints.first;
                      _mapController?.centerOnPoint(first.lat, first.lng, zoom: 13.0);
                    },
                    child: const Icon(Icons.my_location),
                  ),
              ],
            ),
          ),

          // Bottom Sheet: Route Details, Schedule & Stops (like Yandex Maps Transport)
          if (currentRoute != null)
            RouteDetailsSheet(
              route: currentRoute,
              activePoints: activePoints,
              onStopSelected: (stop) {
                setState(() {
                  _selectedStop = stop;
                  _selectedPoint = null;
                });
                _mapController?.centerOnPoint(stop.lat, stop.lng, zoom: 14.5);
              },
            ),
        ],
      ),
    );
  }
}