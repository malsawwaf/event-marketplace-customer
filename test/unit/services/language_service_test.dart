import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_marketplace_customer/services/language_service.dart';

void main() {
  group('LanguageService', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('initialization', () {
      test('should default to English locale', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for async init

        // Assert
        expect(service.currentLocale.languageCode, equals('en'));
        expect(service.isEnglish, isTrue);
        expect(service.isArabic, isFalse);
      });

      test('should load saved language from SharedPreferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'app_language': 'ar',
          'language_selected': true,
        });

        // Act
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(service.currentLocale.languageCode, equals('ar'));
        expect(service.isArabic, isTrue);
        expect(service.languageSelected, isTrue);
      });
    });

    group('setLanguage', () {
      test('should change locale to Arabic', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        bool notified = false;
        service.addListener(() => notified = true);

        // Act
        await service.setLanguage('ar');

        // Assert
        expect(service.currentLocale.languageCode, equals('ar'));
        expect(service.isArabic, isTrue);
        expect(notified, isTrue);
      });

      test('should change locale to English', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({'app_language': 'ar'});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await service.setLanguage('en');

        // Assert
        expect(service.currentLocale.languageCode, equals('en'));
        expect(service.isEnglish, isTrue);
      });

      test('should not notify listeners if language is same', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({'app_language': 'en'});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        int notificationCount = 0;
        service.addListener(() => notificationCount++);

        // Act
        await service.setLanguage('en'); // Same language

        // Assert
        expect(notificationCount, equals(0));
      });

      test('should persist language to SharedPreferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await service.setLanguage('ar');

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_language'), equals('ar'));
      });
    });

    group('toggleLanguage', () {
      test('should toggle from English to Arabic', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({'app_language': 'en'});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await service.toggleLanguage();

        // Assert
        expect(service.isArabic, isTrue);
      });

      test('should toggle from Arabic to English', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({'app_language': 'ar'});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await service.toggleLanguage();

        // Assert
        expect(service.isEnglish, isTrue);
      });
    });

    group('markLanguageAsSelected', () {
      test('should mark language as selected', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.languageSelected, isFalse);

        // Act
        await service.markLanguageAsSelected();

        // Assert
        expect(service.languageSelected, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('language_selected'), isTrue);
      });

      test('should notify listeners when marked', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        bool notified = false;
        service.addListener(() => notified = true);

        // Act
        await service.markLanguageAsSelected();

        // Assert
        expect(notified, isTrue);
      });
    });

    group('textDirection', () {
      test('should return LTR for English', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({'app_language': 'en'});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(service.textDirection, equals(TextDirection.ltr));
      });

      test('should return RTL for Arabic', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({'app_language': 'ar'});
        final service = LanguageService();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(service.textDirection, equals(TextDirection.rtl));
      });
    });
  });
}
