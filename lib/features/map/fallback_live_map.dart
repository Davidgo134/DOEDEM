import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../core/models/route_data.dart';
import '../../core/models/track_point.dart';
import '../../core/utils/geo_utils.dart';
import 'live_map_view.dart';

/// Fallback view shown when Yandex MapKit API key is not provided.
/// Displays an informative Russian banner and a live list of active vehicles.
class FallbackLiveMap extends StatelessWidget {
  final RouteData? route;
  final List<TrackPoint> activePoints;
  final TrackPoint? selectedPoint;
  final VehicleTapCallback? onVehicleTap;

  const FallbackLiveMap({
    super.key,
    required this.route,
    required this.activePoints,
    this.selectedPoint,
    this.onVehicleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // Banner: Map unavailable (no key)
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.amber.shade400, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.map_outlined, color: Colors.amber.shade900, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.mapUnavailableNoKey,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.mapUnavailableHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Route info
          if (route != null) ...[
            Text(
              route!.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: route!.stops.map((stop) {
                return Chip(
                  avatar: const Icon(Icons.place, size: 16),
                  label: Text(stop.name, style: const TextStyle(fontSize: 12)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Active Vehicles Section
          Text(
            AppStrings.mapVehiclesListTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (activePoints.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.directions_bus_outlined, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.passengerNoVehicles,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activePoints.map((point) {
              final isStale = GeoUtils.isPointStale(point);
              final isSelected = selectedPoint == point;
              final ageText = GeoUtils.formatPointAge(point);

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isSelected
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isStale
                          ? Colors.grey.shade400
                          : (point.isDriver ? theme.colorScheme.primary : Colors.teal),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
                  ),
                  title: Text(
                    'Рейс 653 (${point.isDriver ? AppStrings.passengerSourceDriver : AppStrings.passengerSourcePassenger})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$ageText • Скорость: ${(point.speed * 3.6).toStringAsFixed(0)} км/ч',
                    style: TextStyle(
                      color: isStale ? Colors.grey.shade700 : Colors.green.shade800,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onVehicleTap?.call(point),
                ),
              );
            }),
        ],
      ),
    );
  }
}
