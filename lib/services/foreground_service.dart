import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../app/strings.dart';

/// Service managing the Android foreground service and persistent notification.
class ForegroundService {
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'marshrutka_tracking_channel',
        channelName: 'Маршрутка - Трансляция рейса',
        channelDescription: 'Уведомление активной трансляции геопозиции маршрутки',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );

    _isInitialized = true;
  }

  /// Starts the foreground service with specified title and notification message.
  Future<void> start({
    required String title,
    required String body,
  }) async {
    init();

    // Check notification permission (Android 13+)
    final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: body,
      );
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: title,
        notificationText: body,
        notificationButtons: [
          const NotificationButton(
            id: 'btn_stop_shift',
            text: AppStrings.driverShiftStopAction,
          ),
        ],
        callback: _foregroundTaskCallback,
      );
    }
  }

  /// Stops the foreground service.
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// Checks if battery optimizations are ignored.
  Future<bool> isIgnoringBatteryOptimizations() async {
    return FlutterForegroundTask.isIgnoringBatteryOptimizations;
  }

  /// Prompts user to open battery optimization settings.
  Future<bool> requestIgnoreBatteryOptimization() async {
    return FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}

@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_TrackingTaskHandler());
}

class _TrackingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Foreground service started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStopped) async {
    debugPrint('Foreground service destroyed at $timestamp (stopped=$isStopped)');
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_stop_shift') {
      FlutterForegroundTask.stopService();
    }
  }
}
