import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

typedef LocationCallback = void Function(LatLng position, double speed);

class LocationTracker {
  final Location _locationService = Location();
  bool _isTracking = false;

  Future<void> startTracking(LocationCallback callback) async {
    bool serviceEnabled = await _locationService.requestService();
    if (!serviceEnabled) return;

    PermissionStatus permissionGranted = await _locationService.requestPermission();
    if (permissionGranted != PermissionStatus.granted) return;

    _isTracking = true;

    _locationService.onLocationChanged.listen((LocationData locationData) {
      if (!_isTracking) return;
      if (locationData.latitude != null && locationData.longitude != null) {
        LatLng position = LatLng(locationData.latitude!, locationData.longitude!);
        double speed = locationData.speed ?? 0.0; // Speed in m/s
        callback(position, speed);
      }
    });
  }

  void stopTracking() {
    _isTracking = false;
  }
}
