import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:gps_tracker_and_map/domain/entities/route_point.dart';
import 'package:location/location.dart';

class LocationTrackingUseCase {
  final Stream<LocationData> _locationStream;

  LocationTrackingUseCase(this._locationStream);

  Stream<RoutePoint> startTracking() async* {
    await for (var location in _locationStream) {
      if (location.latitude != null && location.longitude != null) {
        yield RoutePoint(
          LatLng(location.latitude!, location.longitude!), DateTime.now(),
          accuracy: location.accuracy ?? double.infinity,  // Pass accuracy if available
        );
      }
    }
  }
}