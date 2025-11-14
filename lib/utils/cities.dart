/// Saudi Arabia cities for location filtering
/// Ordered by population size (major cities first)
class SaudiCities {
  static const String defaultCountry = 'Saudi Arabia';

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
