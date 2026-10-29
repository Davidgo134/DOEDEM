# CHANGELOG

## [Step 4] - Offline Buffer, CSV Trackpoint Logger & Export
- **What works**: Append-only local file/JSON `OfflineBuffer` with chronological FIFO flushing and 2000-point capacity cap (Decision 8), preserving device UTC timestamps during intercity dead zones. `CsvLogger` recording all trackpoints to `trackpoints_log.csv` and export via `share_plus` in Settings (Decision 10). Integration into `TrackingServiceNotifier` to buffer points when disconnected and auto-flush on reconnect. 13/13 unit tests pass, 0 analyzer issues.
- **What is untested on a real device**: Local filesystem I/O speeds on low-end eMMC Android storage under continuous GPS streaming.

## [Step 3] - Location Service, Foreground Notification Service, Driver Shift & Passenger Reporter
- **What works**: `LocationService` with dynamic intervals (10s moving > 1 m/s, 30s stationary <= 1 m/s, LocationAccuracy.high, 10m distanceFilter), `ForegroundService` running Android foreground task with persistent notification ("Смена активна" / "Вы сообщаете о движении маршрутки") and Stop action button, `TrackingService` coordinator broadcasting real-time trackpoints to repository, Driver screen with shift toggle, live GPS signal status, buffered point counter, battery optimization tip banner, and Passenger crowdsourced reporter button. 10/10 tests passing and 0 analyzer issues.
- **What is untested on a real device**: Real GPS satellite acquisition in deep rural dead zones of Volgograd Oblast, and background foreground service behavior under aggressive Android OEM battery managers (MIUI/OneUI).

## [Step 2] - Routes Loader, Mock Simulation & LiveMap Abstraction (Yandex MapKit Lite & Fallback)
- **What works**: Route loader parsing `assets/routes.json` (pilot route №653 Волгоград - Реконструкция), `LocalMockRepository` simulating moving minibus along polyline with dynamic trackpoint broadcasting, swappable `LiveMap` interface hiding Yandex MapKit (`yandex_mapkit_lite`) behind `LiveMapController` / `LiveMap` widget, safe `FallbackLiveMap` ("Карта недоступна: нет ключа" + interactive vehicle list), vehicle age calculation, stale (>90s grey) and expiration (>10m hide) rules, crowdsourced reporter UI toggle, Android Kotlin `MainApplication` with MapKitFactory key initialization from `local.properties` / BuildConfig, and complete test suite (7/7 tests passing, 0 analyzer issues).
- **What is untested on a real device**: OpenGL map rendering and performance on physical Android hardware with various GPU drivers.

## [Step 1] - Project Scaffold, Theme, Strings, Navigation, Role & Consent
- **What works**: Android Flutter project created with null-safety and minSdk 24. Riverpod state management, Material 3 light/dark themes with large bus-friendly touch targets, centralized Russian strings (`strings.dart`), SharedPreferences-backed role selection ("Пассажир" / "Водитель"), anonymous UUID device identity, geolocation consent dialog, and settings screen with role switching. Unit/widget tests pass and `flutter analyze` reports 0 issues.
- **What is untested on a real device**: Physical device appearance across varying Android OEM display scalings and system dark mode transitions.
