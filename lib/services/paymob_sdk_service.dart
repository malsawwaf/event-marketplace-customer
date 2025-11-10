import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/paymob_config.dart';

/// Paymob Native SDK Service
///
/// Bridge between Flutter and native Paymob SDKs (Android & iOS)
/// Handles payment processing using platform-specific implementations
class PaymobSDKService {
  static const methodChannel = MethodChannel('paymob_sdk_flutter');

  /// Call native Paymob SDK to process payment
  ///
  /// Parameters:
  /// - clientSecret: Obtained from Intention API (changes per payment)
  /// - publicKey: From dashboard (constant)
  /// - Optional UI customization parameters
  ///
  /// Returns:
  /// - 'success': true if payment successful
  /// - 'status': 'Successful', 'Rejected', 'Pending', or 'Cancelled'
  /// - 'error': Error message if failed
  Future<Map<String, dynamic>> payWithPaymob({
    required String clientSecret,
    String? publicKey,
    String? appName,
    Color? buttonBackgroundColor,
    Color? buttonTextColor,
    bool? saveCardDefault,
    bool? showSaveCard,
  }) async {
    try {
      print('🔵 Calling native Paymob SDK...');
      print('Public Key: ${publicKey ?? PaymobConfig.publicKey}');
      print('Client Secret: ${clientSecret.substring(0, 20)}...');

      final String result = await methodChannel.invokeMethod('payWithPaymob', {
        "publicKey": publicKey ?? PaymobConfig.publicKey,
        "clientSecret": clientSecret,
        "appName": appName ?? "Event Marketplace",
        "buttonBackgroundColor": buttonBackgroundColor?.value,
        "buttonTextColor": buttonTextColor?.value,
        "saveCardDefault": saveCardDefault ?? false,
        "showSaveCard": showSaveCard ?? false,
      });

      print('Native SDK result: $result');

      switch (result) {
        case 'Successfull': // Note: Typo from native SDK
        case 'Successful':
          print('✅ Transaction Successful');
          return {
            'success': true,
            'status': 'Successful',
          };

        case 'Rejected':
          print('❌ Transaction Rejected');
          return {
            'success': false,
            'status': 'Rejected',
          };

        case 'Pending':
          print('⏳ Transaction Pending');
          return {
            'success': false,
            'status': 'Pending',
          };

        case 'Cancelled':
          print('🚫 Transaction Cancelled by user');
          return {
            'success': false,
            'status': 'Cancelled',
          };

        default:
          print('❓ Unknown response: $result');
          return {
            'success': false,
            'status': 'Unknown',
            'error': 'Unknown response from payment SDK',
          };
      }
    } on PlatformException catch (e) {
      print("❌ Failed to call native SDK: '${e.message}'");
      return {
        'success': false,
        'status': 'Error',
        'error': e.message ?? 'Failed to initialize payment',
      };
    } catch (e) {
      print("❌ Unexpected error: $e");
      return {
        'success': false,
        'status': 'Error',
        'error': e.toString(),
      };
    }
  }

  /// Complete payment flow: Create intention + Launch SDK
  ///
  /// This is the main method to call for processing payments
  Future<Map<String, dynamic>> processPayment({
    required String clientSecret,
    String? appName,
    Color? buttonBackgroundColor,
    Color? buttonTextColor,
  }) async {
    return await payWithPaymob(
      clientSecret: clientSecret,
      appName: appName,
      buttonBackgroundColor: buttonBackgroundColor,
      buttonTextColor: buttonTextColor,
      saveCardDefault: false,
      showSaveCard: true,
    );
  }
}
