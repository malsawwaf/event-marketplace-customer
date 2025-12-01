import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock SupabaseClient for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock SupabaseQueryBuilder for testing database queries
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Mock PostgrestFilterBuilder for testing filters
class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

/// Mock PostgrestTransformBuilder for testing transforms
class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

/// Mock PostgrestBuilder for testing queries
class MockPostgrestBuilder<T> extends Mock implements PostgrestBuilder<T> {}

/// Mock GoTrueClient for testing auth
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock User for testing
class MockUser extends Mock implements User {}

/// Mock Session for testing
class MockSession extends Mock implements Session {}

/// Fake classes for registerFallbackValue
class FakeUri extends Fake implements Uri {}

/// Test data factory for creating mock database responses
class TestDataFactory {
  static Map<String, dynamic> createCart({
    String? id,
    String? customerId,
    String? providerId,
  }) {
    return {
      'id': id ?? 'test-cart-id',
      'customer_id': customerId ?? 'test-customer-id',
      'provider_id': providerId ?? 'test-provider-id',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createCartItem({
    String? id,
    String? cartId,
    String? itemId,
    int quantity = 1,
    String? notes,
  }) {
    return {
      'id': id ?? 'test-cart-item-id',
      'cart_id': cartId ?? 'test-cart-id',
      'item_id': itemId ?? 'test-item-id',
      'quantity': quantity,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createItem({
    String? id,
    String? providerId,
    String? name,
    String? nameAr,
    double price = 100.0,
    String pricingType = 'per_day',
    int stockQuantity = 10,
  }) {
    return {
      'id': id ?? 'test-item-id',
      'provider_id': providerId ?? 'test-provider-id',
      'name': name ?? 'Test Item',
      'name_ar': nameAr ?? 'عنصر اختبار',
      'price': price,
      'pricing_type': pricingType,
      'stock_quantity': stockQuantity,
      'photo_url': 'https://example.com/photo.jpg',
      'is_enabled': true,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createProvider({
    String? id,
    String? companyNameEn,
    String? tradingName,
    String city = 'Jeddah',
  }) {
    return {
      'id': id ?? 'test-provider-id',
      'company_name_en': companyNameEn ?? 'Test Provider',
      'trading_name': tradingName ?? 'مزود اختبار',
      'city': city,
      'country': 'Saudi Arabia',
      'profile_photo_url': 'https://example.com/provider.jpg',
      'average_rating': 4.5,
      'total_reviews': 10,
      'verification_status': 'approved',
      'is_featured': false,
    };
  }

  static Map<String, dynamic> createCustomer({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    return {
      'id': id ?? 'test-customer-id',
      'email': email ?? 'test@example.com',
      'first_name': firstName ?? 'Test',
      'last_name': lastName ?? 'Customer',
      'phone': '+966500000000',
    };
  }

  static Map<String, dynamic> createOrder({
    String? id,
    String? orderNumber,
    String? customerId,
    String? providerId,
    String status = 'pending',
    double totalAmount = 115.0,
  }) {
    return {
      'id': id ?? 'test-order-id',
      'order_number': orderNumber ?? 'ORD-001',
      'customer_id': customerId ?? 'test-customer-id',
      'provider_id': providerId ?? 'test-provider-id',
      'status': status,
      'subtotal': 100.0,
      'vat_amount': 15.0,
      'total_amount': totalAmount,
      'payment_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createStockReservation({
    String? id,
    String? customerId,
    String? itemId,
    String? cartItemId,
    int quantity = 1,
    String status = 'active',
  }) {
    return {
      'id': id ?? 'test-reservation-id',
      'customer_id': customerId ?? 'test-customer-id',
      'item_id': itemId ?? 'test-item-id',
      'cart_item_id': cartItemId ?? 'test-cart-item-id',
      'quantity': quantity,
      'status': status,
      'expires_at': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createAddress({
    String? id,
    String? customerId,
    String label = 'Home',
    String city = 'Jeddah',
    bool isDefault = false,
  }) {
    return {
      'id': id ?? 'test-address-id',
      'customer_id': customerId ?? 'test-customer-id',
      'label': label,
      'street_address': '123 Test Street',
      'city': city,
      'district': 'Test District',
      'postal_code': '12345',
      'is_default': isDefault,
    };
  }

  static Map<String, dynamic> createReview({
    String? id,
    String? customerId,
    String? providerId,
    String? orderId,
    double rating = 4.5,
    String? reviewText,
    bool isAnonymous = false,
  }) {
    return {
      'id': id ?? 'test-review-id',
      'customer_id': customerId ?? 'test-customer-id',
      'provider_id': providerId ?? 'test-provider-id',
      'order_id': orderId ?? 'test-order-id',
      'provider_rating': rating,
      'review_text': reviewText ?? 'Great service!',
      'is_anonymous': isAnonymous,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
