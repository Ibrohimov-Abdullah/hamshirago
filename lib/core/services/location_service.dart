import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  Position? _last;
  Position? get lastPosition => _last;

  Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    _last = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return _last;
  }

  Stream<Position> positionStream() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15));

  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _r(lat2 - lat1); final dLng = _r(lng2 - lng1);
    final a = sin(dLat/2)*sin(dLat/2) + cos(_r(lat1))*cos(_r(lat2))*sin(dLng/2)*sin(dLng/2);
    return r * 2 * atan2(sqrt(a), sqrt(1-a));
  }
  static double _r(double d) => d * pi / 180;
  static int etaMinutes(double km) => (km / 30 * 60).ceil().clamp(1, 999);
}
