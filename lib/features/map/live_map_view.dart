import '../../core/models/route_data.dart';
import '../../core/models/track_point.dart';

typedef VehicleTapCallback = void Function(TrackPoint point);

/// Controller abstraction so feature screens can command the map
/// without depending on the underlying map SDK.
abstract class LiveMapController {
  void centerOnRoute(RouteData route);
  void centerOnPoint(double lat, double lng, {double zoom = 12.0});
}
