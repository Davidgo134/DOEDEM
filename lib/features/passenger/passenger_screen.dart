import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../core/constants.dart';
import '../../core/models/track_point.dart';
import '../../core/utils/geo_utils.dart';
import '../../data/route_loader.dart';
import '../../data/tracking_repository_provider.dart';
import '../../services/location_service.dart';
import '../../services/tracking_service.dart';
import '../consent/consent_dialog.dart';
import '../map/live_map.dart';
import '../map/live_map_view.dart';
import '../settings/settings_screen.dart';

class PassengerScreen extends ConsumerStatefulWidget {
  const PassengerScreen({super.key});

  @override
  ConsumerState<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends ConsumerState<PassengerScreen> {
  LiveMapController? _mapController;
  TrackPoint? _selectedPoint;

  Future<void> _handleReporterToggle(BuildContext context) async {
    final trackingState = ref.read(trackingServiceProvider);

    if (trackingState.isTracking && trackingState.activeSource == 'passenger') {
      await ref.read(trackingServiceProvider.notifier).stopTracking();
      return;
    }

    final hasConsent = ref.read(locationConsentProvider);
    if (!hasConsent) {
      final agreed = await ConsentDialog.show(context);
      if (!agreed) return;
    }

    final success = await ref
        .read(trackingServiceProvider.notifier)
        .startTracking(source: 'passenger');

    if (!success && context.mounted) {
      final currentGps = ref.read(trackingServiceProvider).gpsStatus;
      if (currentGps == GpsSignalStatus.permissionDeniedForever) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.permissionDeniedTitle),
            content: const Text(AppStrings.permissionDeniedPermanentlyMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(locationServiceProvider).openAppSettings();
                },
                child: const Text(AppStrings.permissionSettingsButton),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeAsync = ref.watch(defaultRouteFutureProvider);
    final trackingRepo = ref.watch(trackingRepositoryProvider);
    final pointsAsync = ref.watch(activeRoutePointsStreamProvider(AppConstants.defaultRouteId));
    final trackingState = ref.watch(trackingServiceProvider);
    final isReporterActive = trackingState.isTracking && trackingState.activeSource == 'passenger';

    final rawPoints = pointsAsync.value ?? [];
    // Filter out expired points (> 10 minutes)
    final activePoints = rawPoints.where((p) => !GeoUtils.isPointExpired(p)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(AppStrings.pilotRouteTitle),
            if (trackingRepo.isMock) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  AppStrings.demoModeBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
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
            route: routeAsync.value,
            activePoints: activePoints,
            selectedPoint: _selectedPoint,
            onVehicleTap: (point) {
              setState(() {
                _selectedPoint = point;
              });
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Selected Vehicle Info Card (if clicked)
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
                              'Маршрутка 653 (${_selectedPoint!.isDriver ? AppStrings.passengerSourceDriver : AppStrings.passengerSourcePassenger})',
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
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center_route',
                  tooltip: AppStrings.passengerCenterRoute,
                  onPressed: () {
                    if (routeAsync.hasValue && routeAsync.value != null) {
                      _mapController?.centerOnRoute(routeAsync.value!);
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
                      _mapController?.centerOnPoint(first.lat, first.lng, zoom: 12.0);
                    },
                    child: const Icon(Icons.my_location),
                  ),
              ],
            ),
          ),

          // Bottom Bar: Crowdsourced Reporter Toggle Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isReporterActive)
                      FilledButton.icon(
                        icon: const Icon(Icons.sensors_rounded),
                        label: const Text(AppStrings.passengerReporterStart),
                        onPressed: () => _handleReporterToggle(context),
                      )
                    else
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade400, width: 2),
                        ),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text(AppStrings.passengerReporterStop),
                        onPressed: () => _handleReporterToggle(context),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.passengerReporterHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
