import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../core/models/route_data.dart';
import '../../core/models/track_point.dart';
import '../../services/location_service.dart';
import '../../services/tracking_service.dart';
import '../consent/consent_dialog.dart';
import 'route_picker_sheet.dart';

/// Interactive bottom sheet showing the selected route, schedule,
/// active vehicles count, and the complete stop list (like Yandex Maps Transport).
class RouteDetailsSheet extends ConsumerStatefulWidget {
  final RouteData route;
  final List<TrackPoint> activePoints;
  final void Function(RouteStop stop)? onStopSelected;

  const RouteDetailsSheet({
    super.key,
    required this.route,
    required this.activePoints,
    this.onStopSelected,
  });

  @override
  ConsumerState<RouteDetailsSheet> createState() => _RouteDetailsSheetState();
}

class _RouteDetailsSheetState extends ConsumerState<RouteDetailsSheet> {
  bool _isStopsExpanded = true;

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
        .startTracking(source: 'passenger', routeId: widget.route.id);

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
    final trackingState = ref.watch(trackingServiceProvider);
    final isReporterActive = trackingState.isTracking && trackingState.activeSource == 'passenger';
    final routeColor = _parseRouteColor(widget.route.color);

    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.16,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.16, 0.32, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Header: Route badge + Name + Change route button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: routeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.route.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.route.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.route.type != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.route.type!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Маршруты'),
                    onPressed: () => RoutePickerSheet.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description / Schedule info
              if (widget.route.description != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: routeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.route.description!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Live vehicles count on line
              Row(
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    size: 20,
                    color: widget.activePoints.isNotEmpty ? routeColor : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.activePoints.isEmpty
                        ? 'На линии сейчас нет маршруток'
                        : 'На линии: ${widget.activePoints.length} маршрутк${widget.activePoints.length == 1 ? "а" : "и"}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: widget.activePoints.isNotEmpty
                          ? theme.colorScheme.onSurface
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reporter button: "Я еду в этой маршрутке"
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    children: [
                      if (!isReporterActive)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: routeColor,
                            minimumSize: const Size.fromHeight(42),
                          ),
                          icon: const Icon(Icons.sensors_rounded),
                          label: const Text(AppStrings.passengerReporterStart),
                          onPressed: () => _handleReporterToggle(context),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade400, width: 2),
                            minimumSize: const Size.fromHeight(42),
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
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stops Header (Toggleable)
              InkWell(
                onTap: () {
                  setState(() {
                    _isStopsExpanded = !_isStopsExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Остановки на маршруте (${widget.route.stops.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _isStopsExpanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              // Stops Timeline
              if (_isStopsExpanded) ...[
                const SizedBox(height: 8),
                for (int i = 0; i < widget.route.stops.length; i++) ...[
                  _buildStopItem(
                    context: context,
                    stop: widget.route.stops[i],
                    index: i,
                    total: widget.route.stops.length,
                    routeColor: routeColor,
                  ),
                ],
              ],

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopItem({
    required BuildContext context,
    required RouteStop stop,
    required int index,
    required int total,
    required Color routeColor,
  }) {
    final theme = Theme.of(context);
    final isFirst = index == 0;
    final isLast = index == total - 1;

    return InkWell(
      onTap: () => widget.onStopSelected?.call(stop),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Stop indicator circle with connecting line
            SizedBox(
              width: 24,
              child: Center(
                child: Container(
                  width: isFirst || isLast ? 14 : 10,
                  height: isFirst || isLast ? 14 : 10,
                  decoration: BoxDecoration(
                    color: isFirst || isLast ? routeColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: routeColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Stop name
            Expanded(
              child: Text(
                stop.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: (isFirst || isLast) ? FontWeight.bold : FontWeight.w500,
                  color: (isFirst || isLast)
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),

            Icon(
              Icons.my_location,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}