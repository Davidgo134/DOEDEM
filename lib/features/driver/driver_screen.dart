import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../core/constants.dart';
import '../../core/utils/preferences_service.dart';
import '../../services/location_service.dart';
import '../../services/tracking_service.dart';
import '../consent/consent_dialog.dart';
import '../settings/settings_screen.dart';

class DriverScreen extends ConsumerStatefulWidget {
  const DriverScreen({super.key});

  @override
  ConsumerState<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends ConsumerState<DriverScreen> {
  bool _batteryBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesServiceProvider);
    _batteryBannerDismissed = prefs.isBatteryBannerDismissed();
  }

  void _dismissBatteryBanner() {
    setState(() {
      _batteryBannerDismissed = true;
    });
    ref.read(preferencesServiceProvider).setBatteryBannerDismissed(true);
  }

  Future<void> _handleShiftToggle(BuildContext context) async {
    final trackingState = ref.read(trackingServiceProvider);

    if (trackingState.isTracking) {
      await ref.read(trackingServiceProvider.notifier).stopTracking();
      return;
    }

    // Check consent first
    final hasConsent = ref.read(locationConsentProvider);
    if (!hasConsent) {
      final agreed = await ConsentDialog.show(context);
      if (!agreed) return;
    }

    // Start shift
    final success = await ref
        .read(trackingServiceProvider.notifier)
        .startTracking(source: 'driver');

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
    final isShiftActive = trackingState.isTracking && trackingState.activeSource == 'driver';

    String gpsLabel;
    Color gpsColor;
    IconData gpsIcon;

    switch (trackingState.gpsStatus) {
      case GpsSignalStatus.ok:
        gpsLabel = AppStrings.driverStatusGpsOk;
        gpsColor = Colors.green;
        gpsIcon = Icons.gps_fixed;
        break;
      case GpsSignalStatus.searching:
        gpsLabel = 'Поиск спутников GPS...';
        gpsColor = Colors.orange;
        gpsIcon = Icons.gps_not_fixed;
        break;
      case GpsSignalStatus.noSignal:
      case GpsSignalStatus.disabled:
        gpsLabel = AppStrings.driverStatusNoSignal;
        gpsColor = Colors.red;
        gpsIcon = Icons.gps_off;
        break;
      case GpsSignalStatus.permissionDenied:
      case GpsSignalStatus.permissionDeniedForever:
        gpsLabel = 'Доступ к GPS запрещен';
        gpsColor = Colors.red;
        gpsIcon = Icons.location_disabled;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Battery Optimization Tip (Decision 14)
              if (!_batteryBannerDismissed) ...[
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.battery_saver, color: theme.colorScheme.onTertiaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.driverBatteryBannerTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.driverBatteryBannerBody,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _dismissBatteryBanner,
                              child: const Text(AppStrings.driverBatteryBannerDismiss),
                            ),
                            FilledButton.tonal(
                              onPressed: () async {
                                final fg = ref.read(foregroundServiceProvider);
                                await fg.requestIgnoreBatteryOptimization();
                                _dismissBatteryBanner();
                              },
                              child: const Text(AppStrings.driverBatteryBannerButton),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Route Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.driverSelectedRoute,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.defaultRouteName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Card (GPS & Buffered points count)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(gpsIcon, color: gpsColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              gpsLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.sync_alt, color: Colors.blueGrey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${AppStrings.driverStatusBuffered} ${trackingState.bufferedPointsCount}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Big Shift Action Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(68),
                  backgroundColor: isShiftActive ? Colors.red.shade700 : theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(
                  isShiftActive ? Icons.stop_circle_rounded : Icons.play_arrow_rounded,
                  size: 32,
                ),
                label: Text(
                  isShiftActive ? AppStrings.driverShiftEnd : AppStrings.driverShiftStart,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _handleShiftToggle(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
