import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/paymob_config.dart';

/// Paymob Intention API Service
///
/// Creates payment intentions using the Paymob Intention API
/// Returns client_secret needed for the native SDK
class PaymobIntentionService {

  /// Create a payment intention and get client_secret
  ///
  /// Returns a Map with:
  /// - 'client_secret': String - to be used with native SDK
  /// - 'intention_id': String - unique intention identifier
  /// - 'error': String? - error message if failed
  Future<Map<String, dynamic>> createIntention({
    required double amount, // Amount in SAR (will be converted to cents)
    required String customerFirstName,
    required String customerLastName,
    required String customerEmail,
    required String customerPhone,
    required String orderNumber,
    List<Map<String, dynamic>>? items,
    String? country,
  }) async {
    try {
      // Convert amount to cents (Paymob requires amount in cents)
      final amountInCents = (amount * 100).toInt();

      // Prepare request body
      final requestBody = {
        'amount': amountInCents,
        'currency': PaymobConfig.currency,
        'payment_methods': [PaymobConfig.cardIntegrationId],
        'billing_data': {
          'first_name': customerFirstName,
          'last_name': customerLastName,
          'email': customerEmail,
          'phone_number': customerPhone,
          if (country != null) 'country': country,
        },
        'customer': {
          'first_name': customerFirstName,
          'last_name': customerLastName,
          'email': customerEmail,
        },
        'special_reference': orderNumber,
      };

      // Add items if provided
      if (items != null && items.isNotEmpty) {
        requestBody['items'] = items;
      }

      print('🔵 Creating Paymob Intention...');
      print('Amount: ${amount} SAR (${amountInCents} cents)');
      print('Integration ID: ${PaymobConfig.cardIntegrationId}');

      // Make POST request to Intention API
      final response = await http.post(
        Uri.parse(PaymobConfig.intentionEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${PaymobConfig.secretKey}',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ Authorization Header: ${PaymobConfig.secretKey.substring(0, 20)}...');
        print('❌ Request Body: ${jsonEncode(requestBody)}');
      }
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Extract client_secret from response
        final clientSecret = data['client_secret'] as String?;
        final intentionId = data['id'] as String?;

        if (clientSecret == null) {
          print('❌ Error: No client_secret in response');
          return {
            'error': 'Failed to get client_secret from Paymob',
          };
        }

        print('✅ Intention created successfully');
        print('Client Secret: ${clientSecret.substring(0, 20)}...');

        return {
          'client_secret': clientSecret,
          'intention_id': intentionId,
        };
      } else {
        print('❌ Intention API error: ${response.statusCode}');
        print('Response: ${response.body}');

        return {
          'error': 'Failed to create payment intention: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Exception in createIntention: $e');
      return {
        'error': 'Failed to create payment intention: $e',
      };
    }
  }

  /// Verify transaction status by checking intention details
  ///
  /// Returns a Map with:
  /// - 'success': bool - true if payment was successful
  /// - 'status': String - transaction status from Paymob
  /// - 'error': String? - error message if failed
  Future<Map<String, dynamic>> verifyTransaction(String intentionId) async {
    try {
      print('🔍 Verifying transaction status for intention: $intentionId');

      // Get intention details from Paymob API
      final response = await http.get(
        Uri.parse('${PaymobConfig.intentionEndpoint}$intentionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${PaymobConfig.secretKey}',
        },
      );

      print('Verify response status: ${response.statusCode}');
      print('Verify response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check transaction status
        final status = data['status'] as String?;
        final transactionId = data['transaction_id'] as String?;

        print('Transaction Status: $status');
        print('Transaction ID: $transactionId');

        // Paymob statuses: CREATED, PENDING, SUCCESSFUL, FAILED
        final isSuccessful = status == 'SUCCESSFUL' ||
                            (transactionId != null && transactionId.isNotEmpty);

        return {
          'success': isSuccessful,
          'status': status ?? 'UNKNOWN',
          'transaction_id': transactionId,
          'data': data,
        };
      } else {
        print('❌ Failed to verify transaction: ${response.statusCode}');
        return {
          'success': false,
          'status': 'VERIFICATION_FAILED',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Exception verifying transaction: $e');
      return {
        'success': false,
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Create items array for the intention request
  ///
  /// Converts cart items to Paymob's format
  static List<Map<String, dynamic>> createItemsArray({
    required List<Map<String, dynamic>> cartItems,
  }) {
    return cartItems.map((item) {
      final itemTotal = (item['total'] as num).toDouble();
      final itemTotalCents = (itemTotal * 100).toInt();

      return {
        'name': item['name'] as String,
        'amount': itemTotalCents,
        'description': item['description'] ?? '',
        'quantity': item['quantity'] ?? 1,
      };
    }).toList();
  }
}
