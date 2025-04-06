import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';

class LocationManager {
  // Singleton instance
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  Position? _lastKnownPosition;
  bool _isInitialized = false;

  // Initialize location services
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      print("Error initializing location services: $e");
      return false;
    }
  }

  // Get current position with high accuracy
  Future<Position?> getCurrentPosition() async {
    if (!await initialize()) {
      return null;
    }

    try {
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      return _lastKnownPosition;
    } catch (e) {
      print("Error getting current position: $e");
      return null;
    }
  }

  // Get last known position or fetch a new one
  Future<Position?> getPosition() async {
    if (_lastKnownPosition != null) {
      return _lastKnownPosition;
    }

    return getCurrentPosition();
  }

  // Convert Position to a Map with latitude and longitude doubles
  Map<String, double>? positionToLocationMap(Position? position) {
    if (position == null) return null;
    return {
      'latitude': position.latitude,
      'longitude': position.longitude
    };
  }
}