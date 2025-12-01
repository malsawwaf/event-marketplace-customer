import 'package:flutter_test/flutter_test.dart';

/// Pure function tests for cart calculation logic
/// These tests don't require Supabase initialization
void main() {
  group('Cart Calculations', () {
    group('calculateCartTotals', () {
      test('should calculate correct totals for single item without addons', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 100.0},
            'quantity': 1,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['subtotal'], equals(100.0));
        expect(result['vat'], equals(15.0)); // 15% VAT
        expect(result['delivery_fee'], equals(0.0));
        expect(result['discount'], equals(0.0));
        expect(result['total'], equals(115.0));
      });

      test('should calculate correct totals for multiple items', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 100.0},
            'quantity': 2,
            'addons': null,
          },
          {
            'items': {'price': 50.0},
            'quantity': 3,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        // (100 * 2) + (50 * 3) = 200 + 150 = 350
        expect(result['subtotal'], equals(350.0));
        expect(result['vat'], equals(52.5)); // 15% of 350
        expect(result['total'], equals(402.5));
      });

      test('should include addon prices in calculation', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 100.0},
            'quantity': 2,
            'addons': [
              {'additional_price': 10.0},
              {'additional_price': 20.0},
            ],
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        // Base: 100 * 2 = 200
        // Addons: (10 + 20) * 2 = 60
        // Subtotal = 260
        expect(result['subtotal'], equals(260.0));
        expect(result['vat'], equals(39.0)); // 15% of 260
        expect(result['total'], equals(299.0));
      });

      test('should apply delivery fee correctly', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 100.0},
            'quantity': 1,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(
          cartItems: cartItems,
          deliveryFee: 25.0,
        );

        // Assert
        expect(result['subtotal'], equals(100.0));
        expect(result['vat'], equals(15.0));
        expect(result['delivery_fee'], equals(25.0));
        expect(result['total'], equals(140.0)); // 100 + 15 + 25
      });

      test('should apply discount correctly', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 100.0},
            'quantity': 1,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(
          cartItems: cartItems,
          discountAmount: 20.0,
        );

        // Assert
        expect(result['subtotal'], equals(100.0));
        expect(result['vat'], equals(15.0));
        expect(result['discount'], equals(20.0));
        expect(result['total'], equals(95.0)); // 100 + 15 - 20
      });

      test('should handle empty cart', () {
        // Arrange
        final List<Map<String, dynamic>> cartItems = [];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['subtotal'], equals(0.0));
        expect(result['vat'], equals(0.0));
        expect(result['total'], equals(0.0));
      });

      test('should handle complex scenario with all factors', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 200.0},
            'quantity': 2,
            'addons': [
              {'additional_price': 25.0},
            ],
          },
          {
            'items': {'price': 150.0},
            'quantity': 1,
            'addons': [
              {'additional_price': 10.0},
              {'additional_price': 15.0},
            ],
          }
        ];

        // Act
        final result = calculateCartTotals(
          cartItems: cartItems,
          deliveryFee: 30.0,
          discountAmount: 50.0,
        );

        // Assert
        // Item 1: (200 * 2) + (25 * 2) = 450
        // Item 2: (150 * 1) + (10 + 15) * 1 = 175
        // Subtotal = 625
        // VAT = 93.75
        // Total = 625 + 93.75 + 30 - 50 = 698.75
        expect(result['subtotal'], equals(625.0));
        expect(result['vat'], equals(93.75));
        expect(result['delivery_fee'], equals(30.0));
        expect(result['discount'], equals(50.0));
        expect(result['total'], equals(698.75));
      });

      test('should handle empty addons list', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 100.0},
            'quantity': 1,
            'addons': [], // Empty list instead of null
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['subtotal'], equals(100.0));
        expect(result['total'], equals(115.0));
      });

      test('should handle integer prices', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 100}, // int instead of double
            'quantity': 1,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['subtotal'], equals(100.0));
        expect(result['vat'], equals(15.0));
      });

      test('should calculate VAT at exactly 15%', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 1000.0},
            'quantity': 1,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['vat'], equals(150.0)); // 15% of 1000
        expect(result['total'], equals(1150.0));
      });

      test('should handle multiple addons per item', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 50.0},
            'quantity': 3,
            'addons': [
              {'additional_price': 5.0},
              {'additional_price': 10.0},
              {'additional_price': 15.0},
            ],
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        // Base: 50 * 3 = 150
        // Addons: (5 + 10 + 15) * 3 = 90
        // Subtotal = 240
        expect(result['subtotal'], equals(240.0));
        expect(result['vat'], equals(36.0)); // 15% of 240
        expect(result['total'], equals(276.0));
      });

      test('should handle zero price items', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 0.0},
            'quantity': 1,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['subtotal'], equals(0.0));
        expect(result['vat'], equals(0.0));
        expect(result['total'], equals(0.0));
      });

      test('should handle large quantities', () {
        // Arrange
        final cartItems = [
          {
            'items': {'price': 10.0},
            'quantity': 100,
            'addons': null,
          }
        ];

        // Act
        final result = calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['subtotal'], equals(1000.0));
        expect(result['vat'], equals(150.0));
        expect(result['total'], equals(1150.0));
      });
    });
  });
}

/// Pure function to calculate cart totals
/// This mirrors the logic in CartService.calculateCartTotals
Map<String, double> calculateCartTotals({
  required List<Map<String, dynamic>> cartItems,
  double deliveryFee = 0,
  double discountAmount = 0,
}) {
  double subtotal = 0;

  for (final cartItem in cartItems) {
    final item = cartItem['items'] as Map<String, dynamic>;
    final quantity = cartItem['quantity'] as int;
    final price = (item['price'] as num).toDouble();

    // Calculate item price
    double itemPrice = price * quantity;

    // Add add-ons price
    final addons = cartItem['addons'] as List<dynamic>?;
    if (addons != null && addons.isNotEmpty) {
      for (final addon in addons) {
        final addonPrice = (addon['additional_price'] as num).toDouble();
        itemPrice += addonPrice * quantity;
      }
    }

    subtotal += itemPrice;
  }

  final vatAmount = subtotal * 0.15; // 15% VAT
  final total = subtotal + vatAmount + deliveryFee - discountAmount;

  return {
    'subtotal': subtotal,
    'vat': vatAmount,
    'delivery_fee': deliveryFee,
    'discount': discountAmount,
    'total': total,
  };
}
