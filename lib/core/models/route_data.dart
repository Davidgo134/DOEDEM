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
  final String? description;
  final String? type;
  final String? color;
  final List<RouteStop> stops;
  final List<RouteCoord> polyline;
  final bool? todoVerify;

  const RouteData({
    required this.id,
    required this.name,
    this.description,
    this.type,
    this.color,
    required this.stops,
    required this.polyline,
    this.todoVerify,
  });

  RouteData copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? color,
    List<RouteStop>? stops,
    List<RouteCoord>? polyline,
    bool? todoVerify,
  }) {
    return RouteData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      color: color ?? this.color,
      stops: stops ?? this.stops,
      polyline: polyline ?? this.polyline,
      todoVerify: todoVerify ?? this.todoVerify,
    );
  }

  String get originName {
    if (stops.isNotEmpty) return stops.first.name;
    final parts = name.split('-');
    return parts.first.trim();
  }

  String get destinationName {
    if (stops.length > 1) return stops.last.name;
    final parts = name.split('-');
    return parts.length > 1 ? parts.last.trim() : name;
  }

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String?,
      color: json['color'] as String?,
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
