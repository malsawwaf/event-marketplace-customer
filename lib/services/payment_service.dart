import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/paymob_config.dart';

/// Payment Service for Paymob Integration
/// Handles online card payments via Paymob Accept Payment Gateway
class PaymentService {
  /// Step 1: Authenticate with Paymob and get auth token
  Future<String?> _getAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse(PaymobConfig.authEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': PaymobConfig.apiKey}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  /// Step 2: Create order with Paymob
  Future<int?> _createPaymobOrder({
    required String authToken,
    required double amountCents, // Amount in cents (e.g., 100.50 SAR = 10050 cents)
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(PaymobConfig.orderEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': authToken,
          'delivery_needed': 'false',
          'amount_cents': amountCents.toInt().toString(),
          'currency': currency,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as int?;
      }
      return null;
    } catch (e) {
      print('Error creating Paymob order: $e');
      return null;
    }
  }

  /// Step 3: Generate payment key for iframe
  Future<String?> _getPaymentKey({
    required String authToken,
    required int orderId,
    required double amountCents,
    required Map<String, dynamic> billingData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(PaymobConfig.paymentKeyEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': authToken,
          'amount_cents': amountCents.toInt().toString(),
          'expiration': 3600, // Token valid for 1 hour
          'order_id': orderId.toString(),
          'billing_data': billingData,
          'currency': PaymobConfig.currency,
          'integration_id': PaymobConfig.cardIntegrationId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting payment key: $e');
      return null;
    }
  }

  /// Main method: Initiate payment and return iframe URL
  ///
  /// Returns the complete iframe URL to load in WebView
  /// Returns null if any step fails
  Future<String?> initiatePayment({
    required double amount, // Amount in SAR (e.g., 150.50)
    required String orderNumber,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String deliveryAddress,
  }) async {
    try {
      // Convert amount to cents (Paymob requires amount in cents)
      final amountCents = (amount * 100).round().toDouble();

      // Step 1: Get authentication token
      final authToken = await _getAuthToken();
      if (authToken == null) {
        print('Failed to get auth token');
        return null;
      }

      // Step 2: Create order
      final orderId = await _createPaymobOrder(
        authToken: authToken,
        amountCents: amountCents,
        currency: PaymobConfig.currency,
      );
      if (orderId == null) {
        print('Failed to create order');
        return null;
      }

      // Step 3: Prepare billing data
      final billingData = {
        'first_name': customerName.split(' ').first,
        'last_name': customerName.split(' ').length > 1
            ? customerName.split(' ').last
            : customerName,
        'email': customerEmail,
        'phone_number': customerPhone,
        'apartment': 'NA',
        'floor': 'NA',
        'street': deliveryAddress,
        'building': 'NA',
        'shipping_method': 'NA',
        'postal_code': 'NA',
        'city': 'Riyadh',
        'country': 'SA',
        'state': 'NA',
      };

      // Step 4: Get payment key
      final paymentKey = await _getPaymentKey(
        authToken: authToken,
        orderId: orderId,
        amountCents: amountCents,
        billingData: billingData,
      );
      if (paymentKey == null) {
        print('Failed to get payment key');
        return null;
      }

      // Step 5: Construct payment URL
      // Using direct payment URL (better for mobile apps)
      // No iframe ID needed!
      final paymentUrl = 'https://accept.paymob.com/api/acceptance/payment/pay'
          '?payment_token=$paymentKey';

      return paymentUrl;
    } catch (e) {
      print('Error initiating payment: $e');
      return null;
    }
  }

  /// Verify payment transaction
  /// Call this after payment is completed to verify the result
  ///
  /// Returns true if payment was successful
  bool verifyPaymentCallback({
    required Map<String, dynamic> callbackData,
  }) {
    try {
      // Check if payment was successful
      final success = callbackData['success'] == 'true' ||
                     callbackData['success'] == true;

      // Check if transaction was pending (awaiting confirmation)
      final pending = callbackData['pending'] == 'true' ||
                     callbackData['pending'] == true;

      // You can also validate HMAC if configured in Paymob dashboard
      // final hmac = callbackData['hmac'];
      // TODO: Implement HMAC validation for production

      return success && !pending;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }

  /// Get transaction details from callback
  /// Extracts important transaction info from Paymob callback
  Map<String, dynamic>? getTransactionDetails(Map<String, dynamic> callbackData) {
    try {
      return {
        'transaction_id': callbackData['id']?.toString() ?? callbackData['txn_response_code'],
        'order_id': callbackData['order']?.toString() ?? callbackData['merchant_order_id'],
        'amount_cents': callbackData['amount_cents'],
        'currency': callbackData['currency'],
        'success': callbackData['success'],
        'pending': callbackData['pending'],
        'is_void': callbackData['is_void'],
        'is_refund': callbackData['is_refund'],
        'created_at': callbackData['created_at'],
      };
    } catch (e) {
      print('Error extracting transaction details: $e');
      return null;
    }
  }
}
