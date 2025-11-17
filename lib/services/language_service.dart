import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _languageSelectedKey = 'language_selected';
  Locale _currentLocale = const Locale('en');
  bool _languageSelected = false;

  Locale get currentLocale => _currentLocale;
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get languageSelected => _languageSelected;

  LanguageService() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      _languageSelected = prefs.getBool(_languageSelectedKey) ?? false;
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
      } catch (e) {
        debugPrint('Error saving language: $e');
      }
    }
  }

  Future<void> markLanguageAsSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_languageSelectedKey, true);
      _languageSelected = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking language as selected: $e');
    }
  }

  Future<void> toggleLanguage() async {
    final newLanguage = isEnglish ? 'ar' : 'en';
    await setLanguage(newLanguage);
  }

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
}
