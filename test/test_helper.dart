import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initialize test environment
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
}

/// Test widget wrapper with Material app
Widget testableWidget({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return MaterialApp(
    locale: locale,
    theme: theme ?? ThemeData.light(),
    home: Scaffold(body: child),
  );
}

/// Test widget wrapper with navigation support
Widget testableWidgetWithNavigation({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    home: child,
  );
}

/// Extension for common test matchers
extension WidgetTesterExtensions on WidgetTester {
  /// Find widget by text and tap it
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  /// Find widget by key and tap it
  Future<void> tapByKey(Key key) async {
    await tap(find.byKey(key));
    await pumpAndSettle();
  }

  /// Enter text in a text field by key
  Future<void> enterTextByKey(Key key, String text) async {
    await enterText(find.byKey(key), text);
    await pumpAndSettle();
  }

  /// Scroll until widget is visible
  Future<void> scrollUntilVisible(
    Finder finder, {
    double delta = 100.0,
    int maxScrolls = 50,
  }) async {
    int scrolls = 0;
    while (!any(finder) && scrolls < maxScrolls) {
      await drag(find.byType(Scrollable).first, Offset(0, -delta));
      await pumpAndSettle();
      scrolls++;
    }
  }
}

/// Common test constants
class TestConstants {
  static const String testCustomerId = 'test-customer-id-12345';
  static const String testProviderId = 'test-provider-id-67890';
  static const String testItemId = 'test-item-id-abcde';
  static const String testCartId = 'test-cart-id-fghij';
  static const String testOrderId = 'test-order-id-klmno';
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'TestPassword123!';
  static const String testPhone = '+966500000000';
}

/// Test data builder for creating mock responses
class TestDataBuilder {
  static Map<String, dynamic> buildCartTotals({
    double subtotal = 100.0,
    double vat = 15.0,
    double deliveryFee = 0.0,
    double discount = 0.0,
  }) {
    return {
      'subtotal': subtotal,
      'vat': vat,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total': subtotal + vat + deliveryFee - discount,
    };
  }

  static List<Map<String, dynamic>> buildCartItems({
    int count = 1,
    double basePrice = 100.0,
    int quantity = 1,
    bool withAddons = false,
  }) {
    return List.generate(count, (index) {
      final item = {
        'id': 'cart-item-$index',
        'items': {
          'id': 'item-$index',
          'name': 'Test Item $index',
          'price': basePrice + (index * 10),
        },
        'quantity': quantity,
        'addons': withAddons
            ? [
                {'additional_price': 10.0, 'name': 'Addon 1'},
                {'additional_price': 15.0, 'name': 'Addon 2'},
              ]
            : null,
      };
      return item;
    });
  }
}

/// Mock service results
class MockResults {
  static final successResult = {'success': true};
  static final errorResult = {'success': false, 'error': 'Test error'};

  static Map<String, dynamic> favoritesCounts({
    int items = 0,
    int providers = 0,
  }) {
    return {
      'items': items,
      'providers': providers,
      'total': items + providers,
    };
  }
}
