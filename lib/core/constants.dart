/// Global constants for the Marshrutka application.
class AppConstants {
  // OpenStreetMap Tile Configuration (Raster tiles, no API key required)
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapUserAgentPackageName = 'ru.marshrutka.marshrutka';

  // Pilot Route
  static const String defaultRouteId = '653';
  static const String defaultRouteName = '653 Волгоград - Реконструкция';

  // Timing & GPS Frequency (Decision 7)
  static const int movingIntervalSeconds = 10;
  static const int stationaryIntervalSeconds = 30;
  static const double movingSpeedThresholdMps = 1.0; // 1 m/s
  static const int locationDistanceFilterMeters = 10;

  // Stale & Expiration thresholds (Decision 6)
  static const int staleMarkerThresholdSeconds = 90; // Marker turns grey
  static const int hideMarkerThresholdSeconds = 600; // 10 minutes -> disappears

  // Merge logic thresholds (Decision 9)
  static const double mergeMaxDistanceMeters = 150.0;
  static const int mergeMaxTimeDiffSeconds = 60;

  // Offline buffer limits (Decision 8)
  static const int maxOfflineBufferPoints = 2000;

  // SharedPreferences Keys
  static const String prefKeyUserRole = 'marshrutka_user_role';
  static const String prefKeyDeviceId = 'marshrutka_device_id';
  static const String prefKeyLocationConsent = 'marshrutka_location_consent';
  static const String prefKeyBatteryBannerDismissed = 'marshrutka_battery_banner_dismissed';

  // Storage filenames
  static const String offlineBufferFileName = 'offline_points_buffer.json';
  static const String trackpointCsvFileName = 'trackpoints_log.csv';
}
