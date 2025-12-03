/// Saudi Arabia cities for location filtering
/// Ordered by population size (major cities first)
class SaudiCities {
  static const String defaultCountry = 'Saudi Arabia';
  static const String defaultCountryAr = 'المملكة العربية السعودية';

  /// City coordinates for map centering
  static const Map<String, Map<String, double>> cityCoordinates = {
    'Riyadh': {'lat': 24.7136, 'lng': 46.6753},
    'Jeddah': {'lat': 21.5433, 'lng': 39.1728},
    'Mecca': {'lat': 21.3891, 'lng': 39.8579},
    'Medina': {'lat': 24.5247, 'lng': 39.5692},
    'Dammam': {'lat': 26.4207, 'lng': 50.0888},
    'Khobar': {'lat': 26.2172, 'lng': 50.1971},
    'Dhahran': {'lat': 26.2361, 'lng': 50.0393},
    'Taif': {'lat': 21.2705, 'lng': 40.4158},
    'Buraidah': {'lat': 26.3292, 'lng': 43.9750},
    'Tabuk': {'lat': 28.3838, 'lng': 36.5549},
    'Khamis Mushait': {'lat': 18.3002, 'lng': 42.7331},
    'Hail': {'lat': 27.5219, 'lng': 41.6909},
    'Hafar Al-Batin': {'lat': 28.4394, 'lng': 45.9713},
    'Jubail': {'lat': 27.0046, 'lng': 49.6228},
    'Al Ahsa': {'lat': 25.4075, 'lng': 49.5876},
    'Najran': {'lat': 17.4924, 'lng': 44.1277},
    'Yanbu': {'lat': 24.0895, 'lng': 38.0618},
    'Abha': {'lat': 18.2164, 'lng': 42.5053},
    'Qatif': {'lat': 26.5214, 'lng': 50.0073},
    'Arar': {'lat': 30.9753, 'lng': 41.0245},
    'Sakaka': {'lat': 29.9733, 'lng': 40.2064},
    'Jizan': {'lat': 16.8892, 'lng': 42.5511},
    'Al Qunfudhah': {'lat': 19.1273, 'lng': 41.0788},
    'Al Kharj': {'lat': 24.1556, 'lng': 47.3348},
  };

  /// Get coordinates for a city
  static Map<String, double>? getCityCoordinates(String cityName) {
    return cityCoordinates[cityName];
  }

  /// Major cities in Saudi Arabia (Arabic and English names)
  static const List<Map<String, String>> majorCities = [
    {'en': 'Riyadh', 'ar': 'الرياض'},
    {'en': 'Jeddah', 'ar': 'جدة'},
    {'en': 'Mecca', 'ar': 'مكة المكرمة'},
    {'en': 'Medina', 'ar': 'المدينة المنورة'},
    {'en': 'Dammam', 'ar': 'الدمام'},
    {'en': 'Khobar', 'ar': 'الخبر'},
    {'en': 'Dhahran', 'ar': 'الظهران'},
    {'en': 'Taif', 'ar': 'الطائف'},
    {'en': 'Buraidah', 'ar': 'بريدة'},
    {'en': 'Tabuk', 'ar': 'تبوك'},
    {'en': 'Khamis Mushait', 'ar': 'خميس مشيط'},
    {'en': 'Hail', 'ar': 'حائل'},
    {'en': 'Hafar Al-Batin', 'ar': 'حفر الباطن'},
    {'en': 'Jubail', 'ar': 'الجبيل'},
    {'en': 'Al Ahsa', 'ar': 'الأحساء'},
    {'en': 'Najran', 'ar': 'نجران'},
    {'en': 'Yanbu', 'ar': 'ينبع'},
    {'en': 'Abha', 'ar': 'أبها'},
    {'en': 'Qatif', 'ar': 'القطيف'},
    {'en': 'Arar', 'ar': 'عرعر'},
    {'en': 'Sakaka', 'ar': 'سكاكا'},
    {'en': 'Jizan', 'ar': 'جازان'},
    {'en': 'Al Qunfudhah', 'ar': 'القنفذة'},
    {'en': 'Al Kharj', 'ar': 'الخرج'},
  ];

  /// Get list of city names in English
  static List<String> getCityNamesEnglish() {
    return majorCities.map((city) => city['en']!).toList();
  }

  /// Get list of city names in Arabic
  static List<String> getCityNamesArabic() {
    return majorCities.map((city) => city['ar']!).toList();
  }

  /// Get city name in both languages
  static String getCityDisplayName(String cityEn, {bool showArabic = true}) {
    if (!showArabic) return cityEn;

    final city = majorCities.firstWhere(
      (c) => c['en'] == cityEn,
      orElse: () => {'en': cityEn, 'ar': cityEn},
    );

    return '${city['en']} (${city['ar']})';
  }

  /// Check if a city name is valid
  static bool isValidCity(String cityName) {
    return majorCities.any(
      (city) => city['en']?.toLowerCase() == cityName.toLowerCase() ||
                city['ar'] == cityName,
    );
  }

  /// Get English name from Arabic name
  static String? getEnglishName(String arabicName) {
    final city = majorCities.firstWhere(
      (c) => c['ar'] == arabicName,
      orElse: () => {},
    );
    return city['en'];
  }

  /// Get Arabic name from English name
  static String? getArabicName(String englishName) {
    final city = majorCities.firstWhere(
      (c) => c['en']?.toLowerCase() == englishName.toLowerCase(),
      orElse: () => {},
    );
    return city['ar'];
  }

  /// Get localized city name based on locale
  static String getLocalizedCityName(String englishName, bool isArabic) {
    if (!isArabic) return englishName;
    return getArabicName(englishName) ?? englishName;
  }

  /// Get localized country name
  static String getLocalizedCountryName(String englishName, bool isArabic) {
    if (!isArabic) return englishName;
    if (englishName.toLowerCase() == 'saudi arabia') {
      return defaultCountryAr;
    }
    return englishName;
  }

  /// Match GPS coordinates to nearest major city (simplified)
  /// In production, use proper geocoding API
  static String getNearestCity(double latitude, double longitude) {
    // Simple mapping based on approximate coordinates
    // Riyadh: 24.7136° N, 46.6753° E
    if (latitude >= 24.0 && latitude <= 25.5 && longitude >= 46.0 && longitude <= 47.5) {
      return 'Riyadh';
    }
    // Jeddah: 21.5433° N, 39.1728° E
    if (latitude >= 21.0 && latitude <= 22.5 && longitude >= 38.5 && longitude <= 40.0) {
      return 'Jeddah';
    }
    // Mecca: 21.3891° N, 39.8579° E
    if (latitude >= 21.2 && latitude <= 21.6 && longitude >= 39.7 && longitude <= 40.0) {
      return 'Mecca';
    }
    // Medina: 24.5247° N, 39.5692° E
    if (latitude >= 24.0 && latitude <= 25.0 && longitude >= 39.0 && longitude <= 40.0) {
      return 'Medina';
    }
    // Dammam: 26.4207° N, 50.0888° E
    if (latitude >= 26.0 && latitude <= 27.0 && longitude >= 49.5 && longitude <= 50.5) {
      return 'Dammam';
    }

    // Default to Jeddah if can't determine
    return 'Jeddah';
  }
}
