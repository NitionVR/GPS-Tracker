import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gps_tracker_and_map/data/datasources/local/location_service.dart';
import 'package:gps_tracker_and_map/domain/entities/route_point.dart';
import 'package:gps_tracker_and_map/domain/usecases/location_tracking_use_case.dart';

class MapViewModel extends ChangeNotifier {
  final LocationTrackingUseCase _locationTrackingUseCase;
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  List<LatLng> _route = [];
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  double _totalDistance = 0.0;
  DateTime? _startTime;
  String _pace = "0:00 min/km";
  Timer? _timer;
  bool _isReplaying = false;

  MapViewModel(this._locationTrackingUseCase);

  bool _isTracking = false;
  StreamSubscription<RoutePoint>? _locationSubscription;

  List<LatLng> get route => _route;
  double get totalDistance => _totalDistance;
  String get pace => _pace;
  bool get isTracking => _isTracking;

  get mapController => _mapController;
  get polylines => _polylines;
  get markers => _markers;
  get locationService => _locationService;

  bool get isReplaying => _isReplaying;

  Future<void> initializeLocation(LocationService locationService) async {
    bool serviceEnabled = await locationService.isServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    PermissionStatus permissionGranted = await locationService.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return;
    }

    try {
      final LocationData location = await locationService.getCurrentLocation();

      RoutePoint routePoint = RoutePoint(
        LatLng(location.latitude!, location.longitude!),
        DateTime.now(),
        accuracy: location.accuracy ?? double.infinity,  // Pass accuracy from LocationData
      );
      _updateUserLocation(routePoint);

      if (location.latitude != null && location.longitude != null) {
        _mapController.move(
          LatLng(location.latitude!, location.longitude!),
          16.0, // Zoom level
        );
      } else {
        _mapController.move(
          LatLng(0.0, 0.0),
          16.0,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error while getting location: $e');
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void toggleTracking() {
    _isTracking = !_isTracking;
    notifyListeners();

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

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        notifyListeners();
      },
    );

    // Start location tracking using LocationTrackingUseCase stream
    _locationSubscription = _locationTrackingUseCase.startTracking().listen(_updateUserLocation);
  }

  void _stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void _updateUserLocation(RoutePoint routePoint) {
    print("Received location with accuracy: ${routePoint.position.latitude}, ${routePoint.position.longitude}");

    // Define acceptable accuracy based on route length
    double acceptableAccuracy = _route.isEmpty ? 30.0 : 20.0;

    // Check if the location accuracy is above the acceptable threshold
    if (routePoint.accuracy > acceptableAccuracy) {
      print("Skipping location due to poor accuracy: ${routePoint.accuracy}");
      return;
    }

    // Add the new route point
    _route.add(routePoint.position);

    double distance = 0.0;

    if (_route.length > 1) {
      final lastPoint = _route[_route.length - 2];
      distance = Distance().as(
        LengthUnit.Meter,
        lastPoint,
        routePoint.position,
      );

      // Skip small distances (less than 2 meters)
      if (distance < 2) return;

      _totalDistance += distance;

      if (_startTime != null) {
        final elapsedMinutes = DateTime.now().difference(_startTime!).inSeconds / 60.0;
        final paceMinutes = elapsedMinutes / (_totalDistance / 1000.0);
        _pace =
        "${paceMinutes.floor()}:${(paceMinutes % 1 * 60).round().toString().padLeft(2, '0')} min/km";
      }
    }

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
        point: routePoint.position,
        builder: (ctx) => Icon(
          Icons.navigation,
          color: Colors.red,
          size: 20.0,
        ),
      ),
    ];

    if (_route.length % 5 == 0 || distance > 5) {
      _mapController.move(routePoint.position, _mapController.zoom);
    }

    notifyListeners();
  }


  String getElapsedTime() {
    if (_startTime == null) return "0:00";
    final elapsed = DateTime.now().difference(_startTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }


}
