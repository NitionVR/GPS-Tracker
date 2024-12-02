import 'package:latlong2/latlong.dart';

class RoutePoint {
  final LatLng position;
  final DateTime timeStamp;
  final double accuracy;  // Add accuracy as a property

  RoutePoint(this.position, this.timeStamp, {this.accuracy = double.infinity});
}