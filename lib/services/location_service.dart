import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/cities.dart';

class LocationService {
  /// Get user's current location
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get city name from GPS coordinates using geocoding
  Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Check if we're in Saudi Arabia
        final country = placemark.country?.toLowerCase() ?? '';
        final isoCode = placemark.isoCountryCode?.toLowerCase() ?? '';
        final isSaudiArabia = country.contains('saudi') ||
                              isoCode == 'sa' ||
                              country.contains('السعودية');

        if (!isSaudiArabia) {
          print('📍 Location is outside Saudi Arabia ($country), using default');
          return null; // Will trigger default city
        }

        // Try different locality fields
        String? cityName = placemark.locality ??
                          placemark.subAdministrativeArea ??
                          placemark.administrativeArea;

        if (cityName != null && cityName.isNotEmpty) {
          // Try to match with our known Saudi cities
          final matchedCity = _matchKnownCity(cityName);
          // Only return if we found a match - otherwise return null to trigger fallback
          return matchedCity;
        }
      }

      return null;
    } catch (e) {
      print('Error getting city from coordinates: $e');
      return null;
    }
  }

  /// Detect user's current city
  /// Returns city name in English (always returns a valid city, defaults to Riyadh)
  Future<String> detectCurrentCity() async {
    const defaultCity = 'Riyadh';

    try {
      print('🔵 Detecting current city...');

      // Get GPS position
      final position = await getCurrentPosition();
      if (position == null) {
        print('⚠️ Could not get GPS position, using default city: $defaultCity');
        return defaultCity;
      }

      print('🔵 GPS Position: ${position.latitude}, ${position.longitude}');

      // Quick check: if coordinates are clearly outside Saudi Arabia, skip geocoding
      // Saudi Arabia roughly: Lat 16-32, Lng 34-56
      if (position.latitude < 15 || position.latitude > 33 ||
          position.longitude < 33 || position.longitude > 57) {
        print('📍 Coordinates outside Saudi Arabia bounds, using default: $defaultCity');
        return defaultCity;
      }

      // Try geocoding first (more accurate)
      final cityFromGeocoding = await getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (cityFromGeocoding != null) {
        print('✅ City detected via geocoding: $cityFromGeocoding');
        return cityFromGeocoding;
      }

      // Fallback to coordinate-based matching
      final cityFromCoordinates = SaudiCities.getNearestCity(
        position.latitude,
        position.longitude,
      );

      print('✅ City detected via coordinates: $cityFromCoordinates');
      return cityFromCoordinates;

    } catch (e) {
      print('❌ Error detecting city: $e');
      return defaultCity;
    }
  }

  /// Match a city name with known Saudi cities
  String? _matchKnownCity(String cityName) {
    final lowerCityName = cityName.toLowerCase().trim();

    // Exact match
    for (var city in SaudiCities.majorCities) {
      if (city['en']?.toLowerCase() == lowerCityName) {
        return city['en'];
      }
    }

    // Partial match
    for (var city in SaudiCities.majorCities) {
      if (city['en']!.toLowerCase().contains(lowerCityName) ||
          lowerCityName.contains(city['en']!.toLowerCase())) {
        return city['en'];
      }
    }

    // Check alternative spellings
    final alternatives = {
      'riyadh': 'Riyadh',
      'riyad': 'Riyadh',
      'jeddah': 'Jeddah',
      'jidda': 'Jeddah',
      'jiddah': 'Jeddah',
      'makkah': 'Mecca',
      'makka': 'Mecca',
      'madinah': 'Medina',
      'al madinah': 'Medina',
      'dammam': 'Dammam',
      'damam': 'Dammam',
      'alkhobar': 'Khobar',
      'al khobar': 'Khobar',
      'al-khobar': 'Khobar',
      'dhahran': 'Dhahran',
      'zahran': 'Dhahran',
      'taif': 'Taif',
      'taef': 'Taif',
    };

    final match = alternatives[lowerCityName];
    if (match != null) {
      return match;
    }

    return null;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }
}
