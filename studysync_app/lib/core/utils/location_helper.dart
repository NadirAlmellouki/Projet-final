import 'package:geolocator/geolocator.dart';

/// Coordonnées par défaut (Rabat — données seed backend).
class LocationHelper {
  LocationHelper._();

  static const defaultLat = 33.9716;
  static const defaultLng = -6.8498;

  static Future<({double lat, double lng})> getCurrentOrDefault() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (lat: defaultLat, lng: defaultLng);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return (lat: defaultLat, lng: defaultLng);
    }
  }
}
