/// Route data model for route stops and polyline.
class RouteStop {
  final String name;
  final double lat;
  final double lng;
  final bool? todoVerify;

  const RouteStop({
    required this.name,
    required this.lat,
    required this.lng,
    this.todoVerify,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      todoVerify: json['TODO_VERIFY'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      if (todoVerify != null) 'TODO_VERIFY': todoVerify,
    };
  }
}

class RouteCoord {
  final double lat;
  final double lng;
  final bool? todoVerify;

  const RouteCoord({
    required this.lat,
    required this.lng,
    this.todoVerify,
  });

  factory RouteCoord.fromJson(Map<String, dynamic> json) {
    return RouteCoord(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      todoVerify: json['TODO_VERIFY'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (todoVerify != null) 'TODO_VERIFY': todoVerify,
    };
  }
}

class RouteData {
  final String id;
  final String name;
  final List<RouteStop> stops;
  final List<RouteCoord> polyline;
  final bool? todoVerify;

  const RouteData({
    required this.id,
    required this.name,
    required this.stops,
    required this.polyline,
    this.todoVerify,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      id: json['id'] as String,
      name: json['name'] as String,
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      polyline: (json['polyline'] as List<dynamic>?)
              ?.map((e) => RouteCoord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      todoVerify: json['TODO_VERIFY'] as bool?,
    );
  }
}
