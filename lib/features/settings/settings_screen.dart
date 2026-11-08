import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../core/constants.dart';
import '../../core/models/user_role.dart';
import '../../core/utils/preferences_service.dart';
import '../../data/buffer_and_logger_providers.dart';
import '../../data/tracking_repository_provider.dart';
import '../../data/websocket_tracking_repository.dart';
import '../consent/consent_dialog.dart';
import '../role_select/role_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentRole = ref.watch(userRoleProvider);
    final hasConsent = ref.watch(locationConsentProvider);
    final prefsService = ref.watch(preferencesServiceProvider);
    final csvLogger = ref.watch(csvLoggerProvider);
    final deviceId = prefsService.getOrCreateDeviceId();

    final roleLabel = currentRole == UserRole.driver
        ? AppStrings.roleDriver
        : AppStrings.rolePassenger;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Current Role Card
          Card(
            child: ListTile(
              leading: Icon(
                currentRole == UserRole.driver
                    ? Icons.airline_seat_recline_normal_rounded
                    : Icons.person_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              title: const Text(AppStrings.settingsCurrentRole),
              subtitle: Text(
                roleLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  await ref.read(userRoleProvider.notifier).clearRole();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(AppStrings.settingsChangeRole),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Anonymous Device ID
          Card(
            child: ListTile(
              leading: Icon(Icons.fingerprint_rounded, color: theme.colorScheme.secondary),
              title: const Text(AppStrings.settingsDeviceId),
              subtitle: SelectableText(
                deviceId,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: deviceId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID скопирован в буфер обмена'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Real-time WebSocket Server (Render.com)
          Consumer(
            builder: (context, ref, _) {
              final wsStatus = ref.watch(wsConnectionStatusStreamProvider).value ??
                  WsConnectionStatus.disconnected;
              final wsUrl = prefsService.getWebSocketUrl();

              final statusColor = wsStatus == WsConnectionStatus.connected
                  ? Colors.green
                  : wsStatus == WsConnectionStatus.connecting
                      ? Colors.amber
                      : Colors.orange;

              final statusText = wsStatus == WsConnectionStatus.connected
                  ? '● Подключено (онлайн)'
                  : wsStatus == WsConnectionStatus.connecting
                      ? '○ Подключение к серверу...'
                      : '✕ Сервер не подключен';

              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.cloud_sync_rounded,
                    color: statusColor,
                    size: 32,
                  ),
                  title: const Text('Сервер синхронизации (Render.com)'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wsUrl,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Настроить адрес сервера',
                    onPressed: () => _showWebSocketUrlDialog(context, ref, prefsService),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Geolocation Consent
          Card(
            child: ListTile(
              leading: Icon(
                hasConsent ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: hasConsent ? Colors.green : Colors.orange,
              ),
              title: const Text(AppStrings.settingsConsentStatus),
              subtitle: Text(
                hasConsent
                    ? AppStrings.settingsConsentGranted
                    : AppStrings.settingsConsentRevoked,
              ),
              trailing: TextButton(
                onPressed: () async {
                  await ConsentDialog.show(context);
                },
                child: const Text('Изменить'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Export CSV (Decision 10)
          Card(
            child: ListTile(
              leading: Icon(Icons.table_chart_outlined, color: theme.colorScheme.tertiary),
              title: const Text(AppStrings.settingsExportCsv),
              subtitle: const Text('Экспорт накопленного лога координат для анализа'),
              onTap: () async {
                final count = await csvLogger.count();
                if (count == 0) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.settingsExportNoPoints)),
                    );
                  }
                  return;
                }

                final shared = await csvLogger.exportLog();
                if (shared && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.settingsLogExportSuccess)),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // Battery Optimization Tip (Decision 14)
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.battery_alert_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.settingsBatteryOptimization,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.settingsBatteryTip,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWebSocketUrlDialog(
    BuildContext context,
    WidgetRef ref,
    PreferencesService prefsService,
  ) async {
    final currentUrl = prefsService.getWebSocketUrl();
    final controller = TextEditingController(text: currentUrl);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сервер синхронизации'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Укажите WebSocket URL вашего сервера на Render.com:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'URL сервера',
                hintText: 'wss://doedem-transit-server.onrender.com/ws',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Пример: wss://doedem-server.onrender.com/ws\nПоддерживаются wss://, ws:// и https://.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = AppConstants.defaultWebSocketUrl;
            },
            child: const Text('По умолчанию'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final normalized = WebSocketTrackingRepository.normalizeWsUrl(result);
      await prefsService.setWebSocketUrl(normalized);
      ref.read(webSocketTrackingRepositoryProvider)?.updateUrl(normalized);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL сервера сохранён: $normalized')),
        );
      }
    }
  }
}
