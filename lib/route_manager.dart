import 'package:latlong2/latlong.dart';

class RouteManager {
  final List<LatLng> _routePoints = [];
  final Distance _distanceCalculator = Distance();
  double _totalDistance = 0.0;

  void addPoint(LatLng newPoint) {
    if (_routePoints.isNotEmpty) {
      final lastPoint = _routePoints.last;
      double segmentDistance = _distanceCalculator.as(LengthUnit.Meter, lastPoint, newPoint);
      _totalDistance += segmentDistance;
    }
    _routePoints.add(newPoint);
  }

  List<LatLng> get routePoints => _routePoints;

  double get totalDistance => _totalDistance;

  void clearRoute() {
    _routePoints.clear();
    _totalDistance = 0.0;
  }
}
