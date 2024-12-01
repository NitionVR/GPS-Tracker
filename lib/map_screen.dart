import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Location _locationService = Location();

  bool _isTracking = false;
  LocationData? _userLocation;
  StreamSubscription<LocationData>? _locationSubscription;
  List<LatLng> _route = [];
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];

  DateTime? _startTime;
  Timer? _timer;
  double _totalDistance = 0.0;
  String _pace = "0:00 min/km";

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled = await _locationService.requestService();
    if (!serviceEnabled) return;

    PermissionStatus permissionGranted = await _locationService.requestPermission();
    if (permissionGranted != PermissionStatus.granted) return;

    LocationData initialLocation = await _locationService.getLocation();
    _updateUserLocation(initialLocation);
    _mapController.move(
      LatLng(initialLocation.latitude!, initialLocation.longitude!),
      16.0,
    );
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      _startTracking();
    } else {
      _stopTracking();
    }
  }

  void _startTracking() {
    _startTime = DateTime.now();
    _totalDistance = 0.0;
    _route.clear();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
    _locationSubscription = _locationService.onLocationChanged.listen((locationData) {
      _updateUserLocation(locationData);
    });
  }

  void _stopTracking() {
    _locationSubscription?.cancel();
    _timer?.cancel();
    _locationSubscription = null;
  }

  void _updateUserLocation(LocationData locationData) {

    print("Received location with accuracy: ${locationData.accuracy}");

    double acceptableAccuracy = _route.isEmpty ? 30.0 : 20.0;
    if (locationData.accuracy != null && locationData.accuracy! > acceptableAccuracy) {
      print("Skipping location due to poor accuracy: ${locationData.accuracy}");
      return;
    }

    LatLng currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);

    setState(() {
      double distance = 0.0;

      if (_route.isNotEmpty) {
        final lastPoint = _route.last;

        distance = Distance().as(
          LengthUnit.Meter,
          LatLng(lastPoint.latitude, lastPoint.longitude),
          currentLatLng,
        );

        if (distance < 2) return;

        _totalDistance += distance;

        if (_startTime != null) {
          final elapsedMinutes =
              DateTime.now().difference(_startTime!).inSeconds / 60.0;
          final paceMinutes = elapsedMinutes / (_totalDistance / 1000.0);
          _pace =
          "${paceMinutes.floor()}:${(paceMinutes % 1 * 60).round().toString().padLeft(2, '0')} min/km";
        }
      }

      _route.add(currentLatLng);

      _polylines = [
        Polyline(
          points: _route,
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      ];

      _markers = [
        Marker(
          width: 40.0,
          height: 40.0,
          point: currentLatLng,
          builder: (ctx) => Icon(
            Icons.navigation,
            color: Colors.red,
            size: 20.0,
          ),
        ),
      ];

      if (_route.length % 5 == 0 || distance > 5) {
        _mapController.move(currentLatLng, _mapController.zoom);
      }
    });
  }



  String _getElapsedTime() {
    if (_startTime == null) return "0:00";
    final elapsed = DateTime.now().difference(_startTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStat("Pace", _pace),
            _buildStat("Distance", "${(_totalDistance / 1000).toStringAsFixed(2)} km"),
            _buildStat("Time", _getElapsedTime()),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _userLocation != null
                  ? LatLng(_userLocation!.latitude!, _userLocation!.longitude!)
                  : LatLng(0, 0),
              zoom: 16.0,
              maxZoom: 18.0,
              minZoom: 3.0,
              interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: _polylines,
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _toggleTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _isTracking ? 'Stop Tracking' : 'Start Tracking',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.white70)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
