/// A single geographic point broadcast by a driver or passenger reporter.
class TrackPoint {
  final String deviceId;
  final String routeId;
  final double lat;
  final double lng;
  final double speed;
  final double accuracy;
  final String source; // 'driver' or 'passenger'
  final DateTime ts; // UTC timestamp recorded by device

  const TrackPoint({
    required this.deviceId,
    required this.routeId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.accuracy,
    required this.source,
    required this.ts,
  });

  bool get isDriver => source == 'driver';
  bool get isPassenger => source == 'passenger';

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'routeId': routeId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'accuracy': accuracy,
      'source': source,
      'ts': ts.toUtc().toIso8601String(),
    };
  }

  factory TrackPoint.fromJson(Map<String, dynamic> json) {
    return TrackPoint(
      deviceId: json['deviceId'] as String? ?? 'unknown',
      routeId: json['routeId'] as String? ?? '653',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'passenger',
      ts: json['ts'] != null 
          ? DateTime.parse(json['ts'] as String).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  /// Converts this trackpoint to a single CSV row line.
  /// Format: ts_iso,deviceId,routeId,lat,lng,speed,accuracy,source
  String toCsvLine() {
    return '${ts.toUtc().toIso8601String()},$deviceId,$routeId,$lat,$lng,$speed,$accuracy,$source';
  }

  static String csvHeader() {
    return 'ts,deviceId,routeId,lat,lng,speed,accuracy,source';
  }

  static TrackPoint fromCsvLine(String line) {
    final parts = line.split(',');
    if (parts.length < 8) {
      throw FormatException('Invalid CSV line format: $line');
    }
    return TrackPoint(
      ts: DateTime.parse(parts[0]).toUtc(),
      deviceId: parts[1],
      routeId: parts[2],
      lat: double.parse(parts[3]),
      lng: double.parse(parts[4]),
      speed: double.parse(parts[5]),
      accuracy: double.parse(parts[6]),
      source: parts[7],
    );
  }

  TrackPoint copyWith({
    String? deviceId,
    String? routeId,
    double? lat,
    double? lng,
    double? speed,
    double? accuracy,
    String? source,
    DateTime? ts,
  }) {
    return TrackPoint(
      deviceId: deviceId ?? this.deviceId,
      routeId: routeId ?? this.routeId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      source: source ?? this.source,
      ts: ts ?? this.ts,
    );
  }

  @override
  String toString() {
    return 'TrackPoint(deviceId: $deviceId, routeId: $routeId, lat: $lat, lng: $lng, speed: $speed, source: $source, ts: $ts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackPoint &&
        other.deviceId == deviceId &&
        other.routeId == routeId &&
        other.lat == lat &&
        other.lng == lng &&
        other.speed == speed &&
        other.accuracy == accuracy &&
        other.source == source &&
        other.ts.isAtSameMomentAs(ts);
  }

  @override
  int get hashCode {
    return Object.hash(deviceId, routeId, lat, lng, speed, accuracy, source, ts);
  }
}
