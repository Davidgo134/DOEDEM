# CHANGELOG

## [Step 1] - Project Scaffold, Theme, Strings, Navigation, Role & Consent
- **What works**: Android Flutter project created with null-safety and minSdk 24. Riverpod state management, Material 3 light/dark themes with large bus-friendly touch targets, centralized Russian strings (`strings.dart`), SharedPreferences-backed role selection ("Пассажир" / "Водитель"), anonymous UUID device identity, geolocation consent dialog, and settings screen with role switching. Unit/widget tests pass and `flutter analyze` reports 0 issues.
- **What is untested on a real device**: Physical device appearance across varying Android OEM display scalings and system dark mode transitions.
