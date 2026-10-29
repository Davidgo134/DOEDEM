/// All user-visible strings for the "Маршрутка" application in Russian.
class AppStrings {
  // App
  static const String appTitle = 'Маршрутка';
  static const String demoModeBadge = 'Демо-режим';
  static const String pilotRouteTitle = 'Маршрут №653';

  // Map
  static const String mapUnavailableNoKey = 'Карта недоступна: нет ключа';
  static const String mapUnavailableHint = 'Укажите YANDEX_MAPKIT_API_KEY в local.properties или GitHub Secrets.';
  static const String mapVehiclesListTitle = 'Активные маршрутки на рейсе';

  // Roles
  static const String roleSelectTitle = 'Кто вы?';
  static const String roleSelectSubtitle = 'Выберите вашу роль в поездке. Роль можно изменить в любой момент в настройках.';
  static const String rolePassenger = 'Пассажир';
  static const String roleDriver = 'Водитель';
  static const String rolePassengerDesc = 'Смотрите движение маршруток на карте и отмечайте свою поездку.';
  static const String roleDriverDesc = 'Транслируйте координаты во время смены для пассажиров.';

  // Consent
  static const String consentTitle = 'Согласие на передачу геолокации';
  static const String consentButtonAgree = 'Согласен';
  static const String consentButtonDecline = 'Отказаться';
  static const String consentBody = 
      'Приложение «Маршрутка» собирает и передает данные о вашей геолокации только тогда, '
      'когда включен режим трансляции («Смена» или «Я еду в этой маршрутке»).\n\n'
      '• Данные полностью анонимны: передается только случайный идентификатор устройства.\n'
      '• Актуальные координаты удаляются с сервера через 24 часа.\n'
      '• Вы можете остановить передачу координат в любой момент одной кнопкой.\n\n'
      'Без вашего согласия функции трансляции местоположения будут недоступны.';

  // Settings
  static const String settingsTitle = 'Настройки';
  static const String settingsCurrentRole = 'Текущая роль';
  static const String settingsChangeRole = 'Сменить роль';
  static const String settingsExportCsv = 'Экспорт лога (CSV)';
  static const String settingsDeviceId = 'Анонимный ID устройства';
  static const String settingsConsentStatus = 'Согласие на сбор геопозиции';
  static const String settingsConsentGranted = 'Предоставлено';
  static const String settingsConsentRevoked = 'Не предоставлено';
  static const String settingsBatteryOptimization = 'Оптимизация батареи';
  static const String settingsBatteryTip = 'Для непрерывной передачи GPS при выключенном экране рекомендуется отключить оптимизацию батареи.';
  static const String settingsOpenAppSettings = 'Открыть настройки приложения';
  static const String settingsExportNoPoints = 'Нет записанных точек для экспорта';
  static const String settingsLogExportSuccess = 'Лог подготовлен к экспорту';

  // Driver Screen
  static const String driverShiftStart = 'Начать смену';
  static const String driverShiftEnd = 'Закончить смену';
  static const String driverShiftActiveNotification = 'Смена активна';
  static const String driverShiftNotificationBody = 'Трансляция геопозиции маршрутки включена';
  static const String driverShiftStopAction = 'Остановить';
  static const String driverStatusGpsOk = 'GPS сигнал стабилен';
  static const String driverStatusNoSignal = 'Нет сигнала GPS';
  static const String driverStatusBuffered = 'Точек в буфере офлайн:';
  static const String driverSelectedRoute = 'Выбранный маршрут:';
  static const String driverBatteryBannerTitle = 'Фоновая работа GPS';
  static const String driverBatteryBannerBody = 'Чтобы трансляция не прерывалась при выключенном экране, отключите оптимизацию батареи для приложения.';
  static const String driverBatteryBannerButton = 'Настроить';
  static const String driverBatteryBannerDismiss = 'Понятно';

  // Passenger Screen
  static const String passengerReporterStart = 'Я еду в этой маршрутке';
  static const String passengerReporterStop = 'Я вышел из маршрутки';
  static const String passengerReporterHint = 'Покажите маршрутку другим, пока вы в ней едете';
  static const String passengerReporterActiveNotification = 'Вы сообщаете о движении маршрутки';
  static const String passengerSourceDriver = 'водитель';
  static const String passengerSourcePassenger = 'пассажир';
  static const String passengerUpdatedSecAgo = 'обновлено %s сек назад';
  static const String passengerUpdatedMinAgo = 'обновлено %s мин назад';
  static const String passengerUpdatedJustNow = 'обновлено только что';
  static const String passengerNoVehicles = 'На маршруте пока нет активных маршруток';
  static const String passengerCenterRoute = 'К маршруту';
  static const String passengerCenterVehicle = 'К маршрутке';

  // Permissions & Dialogs
  static const String permissionLocationRationaleTitle = 'Доступ к геолокации';
  static const String permissionLocationRationaleMessage = 
      'Приложению необходим доступ к точной геолокации для трансляции движения маршрутки на карте.';
  static const String permissionNotificationRationaleTitle = 'Уведомления';
  static const String permissionNotificationRationaleMessage = 
      'Уведомление необходимо для поддержания фоновой службы и быстрого завершения смены.';
  static const String permissionButtonAllow = 'Продолжить';
  static const String permissionDeniedTitle = 'Геолокация недоступна';
  static const String permissionDeniedPermanentlyMessage = 
      'Разрешение на доступ к геолокации было отклонено навсегда. Пожалуйста, откройте настройки приложения и включите геолокацию вручную.';
  static const String permissionSettingsButton = 'Настройки';
  static const String cancel = 'Отмена';
  static const String ok = 'ОК';
}
