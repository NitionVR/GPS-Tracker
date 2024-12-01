import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapManager {
  final MapController _mapController;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  MapManager(this._mapController);

  void updateMap(LatLng position, List<LatLng> routePoints) {
    _markers = [
      Marker(
        point: position,
        width: 40,
        height: 40,
        builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    ];

    _polylines = [
      Polyline(
        points: routePoints,
        color: Colors.blue,
        strokeWidth: 4.0,
      ),
    ];

    _mapController.move(position, 16);
  }

  List<Marker> get markers => _markers;
  List<Polyline> get polylines => _polylines;
}
