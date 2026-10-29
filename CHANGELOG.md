# CHANGELOG

## [Step 2] - Routes Loader, Mock Simulation & LiveMap Abstraction (Yandex MapKit Lite & Fallback)
- **What works**: Route loader parsing `assets/routes.json` (pilot route №653 Волгоград - Реконструкция), `LocalMockRepository` simulating moving minibus along polyline with dynamic trackpoint broadcasting, swappable `LiveMap` interface hiding Yandex MapKit (`yandex_mapkit_lite`) behind `LiveMapController` / `LiveMap` widget, safe `FallbackLiveMap` ("Карта недоступна: нет ключа" + interactive vehicle list), vehicle age calculation, stale (>90s grey) and expiration (>10m hide) rules, crowdsourced reporter UI toggle, Android Kotlin `MainApplication` with MapKitFactory key initialization from `local.properties` / BuildConfig, and complete test suite (7/7 tests passing, 0 analyzer issues).
- **What is untested on a real device**: OpenGL map rendering and performance on physical Android hardware with various GPU drivers.

## [Step 1] - Project Scaffold, Theme, Strings, Navigation, Role & Consent
- **What works**: Android Flutter project created with null-safety and minSdk 24. Riverpod state management, Material 3 light/dark themes with large bus-friendly touch targets, centralized Russian strings (`strings.dart`), SharedPreferences-backed role selection ("Пассажир" / "Водитель"), anonymous UUID device identity, geolocation consent dialog, and settings screen with role switching. Unit/widget tests pass and `flutter analyze` reports 0 issues.
- **What is untested on a real device**: Physical device appearance across varying Android OEM display scalings and system dark mode transitions.
