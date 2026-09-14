import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position position;
  final String suburb;
  final String state;
  final String countryCode;

  const LocationResult({
    required this.position,
    required this.suburb,
    required this.state,
    required this.countryCode,
  });
}

class LocationService {
  static Future<LocationResult> currentArea() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are turned off.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission was not granted.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );

    final geocoding = Geocoding();
    final places = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final place = places.isEmpty ? null : places.first;
    final suburb = (place?.subLocality?.trim().isNotEmpty ?? false)
        ? place!.subLocality!.trim()
        : ((place?.locality?.trim().isNotEmpty ?? false) ? place!.locality!.trim() : '');
    final state = (place?.administrativeArea ?? '').trim();
    final countryCode = (place?.isoCountryCode ?? '').trim().toUpperCase();

    return LocationResult(
      position: position,
      suburb: suburb,
      state: state,
      countryCode: countryCode,
    );
  }
}
