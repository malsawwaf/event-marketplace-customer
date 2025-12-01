import 'package:flutter_test/flutter_test.dart';
import 'package:event_marketplace_customer/services/cart_service.dart';

void main() {
  group('CartService', () {
    group('calculateCartTotals', () {
      late CartService cartService;

      setUp(() {
        cartService = CartService();
      });

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
        final result = cartService.calculateCartTotals(cartItems: cartItems);

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
        final result = cartService.calculateCartTotals(cartItems: cartItems);

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
        final result = cartService.calculateCartTotals(cartItems: cartItems);

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
        final result = cartService.calculateCartTotals(
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
        final result = cartService.calculateCartTotals(
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
        final result = cartService.calculateCartTotals(cartItems: cartItems);

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
        final result = cartService.calculateCartTotals(
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
        final result = cartService.calculateCartTotals(cartItems: cartItems);

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
        final result = cartService.calculateCartTotals(cartItems: cartItems);

        // Assert
        expect(result['subtotal'], equals(100.0));
        expect(result['vat'], equals(15.0));
      });
    });
  });
}
