import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../core/utils/preferences_service.dart';

final locationConsentProvider = NotifierProvider<LocationConsentNotifier, bool>(LocationConsentNotifier.new);

class LocationConsentNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.hasLocationConsent();
  }

  Future<void> grantConsent() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setLocationConsent(true);
    state = true;
  }

  Future<void> revokeConsent() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setLocationConsent(false);
    state = false;
  }
}

class ConsentDialog extends ConsumerWidget {
  const ConsentDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConsentDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.security_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              AppStrings.consentTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          AppStrings.consentBody,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(locationConsentProvider.notifier).revokeConsent();
            Navigator.of(context).pop(false);
          },
          child: const Text(AppStrings.consentButtonDecline),
        ),
        FilledButton(
          onPressed: () {
            ref.read(locationConsentProvider.notifier).grantConsent();
            Navigator.of(context).pop(true);
          },
          child: const Text(AppStrings.consentButtonAgree),
        ),
      ],
    );
  }
}
