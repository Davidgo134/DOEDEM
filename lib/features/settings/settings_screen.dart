import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../core/models/user_role.dart';
import '../../core/utils/preferences_service.dart';
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

          // Export CSV (will be linked to CsvLogger in step 4)
          Card(
            child: ListTile(
              leading: Icon(Icons.table_chart_outlined, color: theme.colorScheme.tertiary),
              title: const Text(AppStrings.settingsExportCsv),
              subtitle: const Text('Экспорт накопленного лога координат для анализа'),
              onTap: () {
                // In Step 4 this triggers CsvLogger.exportLog()
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.settingsExportNoPoints)),
                );
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
}
